import Foundation

enum ContentRepositoryError: LocalizedError, Equatable {
    case missingResource(String)
    case unreadableResource(String)
    case invalidResource(String, String)
    case unsupportedSchema(Int)
    case manifestCountMismatch(packID: String, expected: Int, actual: Int)
    case duplicateID(UUID)
    case duplicateWordRank(Int)
    case invalidPhraseReference(phraseID: UUID, wordID: UUID)
    case phraseWithoutFocusWord(UUID)
    case emptyWordCollection
    case invalidLanguage(String)
    case duplicatePackID(String)
    case invalidWordRank(wordID: UUID, rank: Int)
    case invalidTeachingPriority(itemID: UUID, priority: Int)
    case invalidContentVersion(itemID: UUID, version: Int)
    case invalidRegionalVariant(itemID: UUID)
    case duplicateRegionalVariant(itemID: UUID, form: String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(resource): "Missing bundled content resource: \(resource)"
        case let .unreadableResource(resource): "Unable to read bundled content resource: \(resource)"
        case let .invalidResource(resource, reason): "Invalid content in \(resource): \(reason)"
        case let .unsupportedSchema(version): "Unsupported content schema version: \(version)"
        case let .manifestCountMismatch(packID, expected, actual):
            "Pack \(packID) declares \(expected) items but contains \(actual)."
        case let .duplicateID(id): "Duplicate content ID: \(id.uuidString)"
        case let .duplicateWordRank(rank): "Duplicate word frequency rank: \(rank)"
        case let .invalidPhraseReference(phraseID, wordID):
            "Phrase \(phraseID.uuidString) references missing word \(wordID.uuidString)."
        case let .phraseWithoutFocusWord(id): "Phrase \(id.uuidString) has no focus word."
        case .emptyWordCollection: "The content manifest does not provide any words."
        case let .invalidLanguage(language): "Unsupported content language: \(language). Expected nb-NO."
        case let .duplicatePackID(id): "Duplicate content pack ID: \(id)"
        case let .invalidWordRank(wordID, rank): "Word \(wordID.uuidString) has invalid frequency rank \(rank)."
        case let .invalidTeachingPriority(itemID, priority):
            "Item \(itemID.uuidString) has invalid teaching priority \(priority)."
        case let .invalidContentVersion(itemID, version):
            "Item \(itemID.uuidString) has invalid content version \(version)."
        case let .invalidRegionalVariant(itemID):
            "Item \(itemID.uuidString) has an empty regional form or region label."
        case let .duplicateRegionalVariant(itemID, form):
            "Item \(itemID.uuidString) repeats the regional form \(form)."
        }
    }
}

struct ContentRepository {
    static let supportedSchemaVersion = 1

    let manifest: ContentManifest
    let words: [WordEntry]
    let phrases: [PhraseEntry]
    private let wordsByID: [UUID: WordEntry]
    private let phrasesByID: [UUID: PhraseEntry]
    private let relatedPhrasesByWordID: [UUID: [PhraseEntry]]
    private let packIDByItemID: [UUID: String]

    init(bundle: Bundle = .main) throws {
        let manifest: ContentManifest = try Self.decode("content-manifest.json", from: bundle)
        guard manifest.schemaVersion == Self.supportedSchemaVersion else {
            throw ContentRepositoryError.unsupportedSchema(manifest.schemaVersion)
        }

        var loadedWords: [WordEntry] = []
        var loadedPhrases: [PhraseEntry] = []
        var loadedPackIDs: [UUID: String] = [:]

        for pack in manifest.packs {
            switch pack.kind {
            case .word:
                let entries: [WordEntry] = try Self.decode(pack.resource, from: bundle)
                guard entries.count == pack.itemCount else {
                    throw ContentRepositoryError.manifestCountMismatch(
                        packID: pack.id,
                        expected: pack.itemCount,
                        actual: entries.count
                    )
                }
                loadedWords.append(contentsOf: entries)
                entries.forEach { loadedPackIDs[$0.id] = pack.id }
            case .phrase:
                let entries: [PhraseEntry] = try Self.decode(pack.resource, from: bundle)
                guard entries.count == pack.itemCount else {
                    throw ContentRepositoryError.manifestCountMismatch(
                        packID: pack.id,
                        expected: pack.itemCount,
                        actual: entries.count
                    )
                }
                loadedPhrases.append(contentsOf: entries)
                entries.forEach { loadedPackIDs[$0.id] = pack.id }
            }
        }

        let sortedWords = loadedWords.sorted { $0.teachingPriority < $1.teachingPriority }
        let sortedPhrases = loadedPhrases.sorted { $0.teachingPriority < $1.teachingPriority }
        words = sortedWords
        phrases = sortedPhrases
        self.manifest = manifest
        wordsByID = Self.index(sortedWords)
        phrasesByID = Self.index(sortedPhrases)
        relatedPhrasesByWordID = Self.relatedPhraseIndex(sortedPhrases)
        packIDByItemID = loadedPackIDs
        try validate()
    }

    init(manifest: ContentManifest, words: [WordEntry], phrases: [PhraseEntry]) throws {
        self.manifest = manifest
        let sortedWords = words.sorted { $0.teachingPriority < $1.teachingPriority }
        let sortedPhrases = phrases.sorted { $0.teachingPriority < $1.teachingPriority }
        self.words = sortedWords
        self.phrases = sortedPhrases
        wordsByID = Self.index(sortedWords)
        phrasesByID = Self.index(sortedPhrases)
        relatedPhrasesByWordID = Self.relatedPhraseIndex(sortedPhrases)
        packIDByItemID = Self.inferPackIDs(manifest: manifest, words: sortedWords, phrases: sortedPhrases)
        try validate()
    }

    func word(withID id: UUID) -> WordEntry? {
        wordsByID[id]
    }

    func phrase(withID id: UUID) -> PhraseEntry? {
        phrasesByID[id]
    }

    func item(withID id: UUID) -> LearningItem? {
        if let word = word(withID: id) {
            return .word(word)
        }
        if let phrase = phrase(withID: id) {
            return .phrase(phrase)
        }
        return nil
    }

    func relatedPhrases(for wordID: UUID) -> [PhraseEntry] {
        relatedPhrasesByWordID[wordID] ?? []
    }

    func packID(for itemID: UUID) -> String? {
        packIDByItemID[itemID]
    }

    private func validate() throws {
        guard manifest.language == "nb-NO" else {
            throw ContentRepositoryError.invalidLanguage(manifest.language)
        }
        guard !words.isEmpty else {
            throw ContentRepositoryError.emptyWordCollection
        }

        var packIDs = Set<String>()
        for pack in manifest.packs where !packIDs.insert(pack.id).inserted {
            throw ContentRepositoryError.duplicatePackID(pack.id)
        }

        var contentIDs = Set<UUID>()
        for id in words.map(\.id) + phrases.map(\.id) {
            guard contentIDs.insert(id).inserted else {
                throw ContentRepositoryError.duplicateID(id)
            }
        }

        var ranks = Set<Int>()
        for word in words {
            guard word.rank > 0 else {
                throw ContentRepositoryError.invalidWordRank(wordID: word.id, rank: word.rank)
            }
            guard word.teachingPriority > 0 else {
                throw ContentRepositoryError.invalidTeachingPriority(
                    itemID: word.id,
                    priority: word.teachingPriority
                )
            }
            guard word.contentVersion > 0 else {
                throw ContentRepositoryError.invalidContentVersion(
                    itemID: word.id,
                    version: word.contentVersion
                )
            }
            guard ranks.insert(word.rank).inserted else {
                throw ContentRepositoryError.duplicateWordRank(word.rank)
            }
            try validateRegionalVariants(word.regionalVariants, itemID: word.id)
        }

        let wordIDs = Set(words.map(\.id))
        for phrase in phrases {
            guard phrase.teachingPriority > 0 else {
                throw ContentRepositoryError.invalidTeachingPriority(
                    itemID: phrase.id,
                    priority: phrase.teachingPriority
                )
            }
            guard phrase.contentVersion > 0 else {
                throw ContentRepositoryError.invalidContentVersion(
                    itemID: phrase.id,
                    version: phrase.contentVersion
                )
            }
            guard !phrase.focusWordIDs.isEmpty else {
                throw ContentRepositoryError.phraseWithoutFocusWord(phrase.id)
            }
            for wordID in phrase.componentWordIDs + phrase.focusWordIDs where !wordIDs.contains(wordID) {
                throw ContentRepositoryError.invalidPhraseReference(phraseID: phrase.id, wordID: wordID)
            }
            try validateRegionalVariants(phrase.regionalVariants, itemID: phrase.id)
        }
    }

    private func validateRegionalVariants(_ variants: [RegionalVariant]?, itemID: UUID) throws {
        var forms = Set<String>()
        for variant in variants ?? [] {
            let form = variant.form.trimmingCharacters(in: .whitespacesAndNewlines)
            let region = variant.region.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !form.isEmpty, !region.isEmpty else {
                throw ContentRepositoryError.invalidRegionalVariant(itemID: itemID)
            }
            let normalized = form.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard forms.insert(normalized).inserted else {
                throw ContentRepositoryError.duplicateRegionalVariant(itemID: itemID, form: form)
            }
        }
    }

    private static func index<Value: Identifiable>(_ values: [Value]) -> [UUID: Value] where Value.ID == UUID {
        Dictionary(values.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func relatedPhraseIndex(_ phrases: [PhraseEntry]) -> [UUID: [PhraseEntry]] {
        var result: [UUID: [PhraseEntry]] = [:]
        for phrase in phrases {
            for id in Set(phrase.componentWordIDs + phrase.focusWordIDs) {
                result[id, default: []].append(phrase)
            }
        }
        return result
    }

    private static func inferPackIDs(
        manifest: ContentManifest,
        words: [WordEntry],
        phrases: [PhraseEntry]
    ) -> [UUID: String] {
        var result: [UUID: String] = [:]
        let wordPacks = manifest.packs.filter { $0.kind == .word }
        for word in words {
            let pack = wordPacks.first { pack in
                (pack.minimumFrequencyRank.map { word.rank >= $0 } ?? true) &&
                    (pack.maximumFrequencyRank.map { word.rank <= $0 } ?? true)
            }
            result[word.id] = pack?.id
        }

        let phrasePacks = manifest.packs.filter { $0.kind == .phrase }
        if phrasePacks.count == 1, let packID = phrasePacks.first?.id {
            phrases.forEach { result[$0.id] = packID }
        }
        return result
    }

    private static func decode<Value: Decodable>(_ resource: String, from bundle: Bundle) throws -> Value {
        let resourceURL = URL(fileURLWithPath: resource)
        let name = resourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = resourceURL.pathExtension

        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw ContentRepositoryError.missingResource(resource)
        }
        guard let data = try? Data(contentsOf: url) else {
            throw ContentRepositoryError.unreadableResource(resource)
        }

        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            throw ContentRepositoryError.invalidResource(resource, error.localizedDescription)
        }
    }
}

struct WordRepository {
    let words: [WordEntry]

    init(bundle: Bundle = .main) {
        do {
            words = try ContentRepository(bundle: bundle).words
        } catch {
            preconditionFailure("Unable to load bundled content: \(error.localizedDescription)")
        }
    }

    func word(withID id: UUID) -> WordEntry? {
        words.first { $0.id == id }
    }
}
