import Foundation

enum LearningMode: String, CaseIterable, Identifiable {
    case mixed
    case words
    case phrases

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mixed: "Mixed"
        case .words: "Words"
        case .phrases: "Phrases"
        }
    }
}

struct LearningRotationStore {
    private let defaults: UserDefaults
    private let wordQueueKey = "learningWordQueue"
    private let phraseQueueKey = "learningPhraseQueue"
    private let wordDatasetKey = "learningWordDataset"
    private let phraseDatasetKey = "learningPhraseDataset"
    private let lastWordKey = "learningLastWord"
    private let lastPhraseKey = "learningLastPhrase"
    private let introducedWordIDsKey = "introducedWordIDs"
    private let mixedPositionKey = "mixedPosition"

    init(defaults: UserDefaults = SharedDefaults.defaults) {
        self.defaults = defaults
    }

    mutating func nextItem(from repository: ContentRepository, mode: LearningMode) -> LearningItem {
        switch mode {
        case .words:
            return .word(nextWord(from: repository.words))
        case .phrases:
            return nextEligiblePhrase(from: repository) ?? .word(nextWord(from: repository.words))
        case .mixed:
            let position = defaults.integer(forKey: mixedPositionKey)
            defaults.set((position + 1) % 5, forKey: mixedPositionKey)
            if position == 4, let phrase = nextEligiblePhrase(from: repository) {
                return phrase
            }
            return .word(nextWord(from: repository.words))
        }
    }

    mutating func markIntroduced(_ item: LearningItem) {
        guard case let .word(word) = item else { return }
        var introduced = Set(defaults.stringArray(forKey: introducedWordIDsKey) ?? [])
        introduced.insert(word.id.uuidString)
        defaults.set(Array(introduced).sorted(), forKey: introducedWordIDsKey)
    }

    private mutating func nextWord(from words: [WordEntry]) -> WordEntry {
        precondition(!words.isEmpty, "Cannot rotate through an empty word list")
        let nextID = nextID(
            candidates: words.map(\.id),
            queueKey: wordQueueKey,
            datasetKey: wordDatasetKey,
            lastKey: lastWordKey
        )
        let word = words.first { $0.id == nextID } ?? words[0]
        markIntroduced(.word(word))
        return word
    }

    private mutating func nextEligiblePhrase(from repository: ContentRepository) -> LearningItem? {
        let introduced = Set((defaults.stringArray(forKey: introducedWordIDsKey) ?? []).compactMap(UUID.init))
        let eligible = repository.phrases.filter { phrase in
            phrase.isStandalone || Set(phrase.focusWordIDs).isSubset(of: introduced)
        }
        guard !eligible.isEmpty else { return nil }

        let nextID = nextID(
            candidates: eligible.map(\.id),
            queueKey: phraseQueueKey,
            datasetKey: phraseDatasetKey,
            lastKey: lastPhraseKey
        )
        return eligible.first { $0.id == nextID }.map(LearningItem.phrase)
    }

    private func nextID(candidates: [UUID], queueKey: String, datasetKey: String, lastKey: String) -> UUID {
        precondition(!candidates.isEmpty, "Cannot rotate through an empty candidate list")
        let candidateStrings = candidates.map(\.uuidString)
        let signature = candidateStrings.sorted().joined(separator: ",")
        var queue = defaults.stringArray(forKey: queueKey) ?? []
        let available = Set(candidateStrings)
        queue.removeAll { !available.contains($0) }

        if defaults.string(forKey: datasetKey) != signature {
            let queued = Set(queue)
            queue.append(contentsOf: available.subtracting(queued).shuffled())
            if queue.count > 1, queue.last == defaults.string(forKey: lastKey) {
                queue.swapAt(queue.count - 1, queue.count - 2)
            }
            defaults.set(signature, forKey: datasetKey)
        }

        if queue.isEmpty {
            queue = candidateStrings.shuffled()
            if queue.count > 1, queue.last == defaults.string(forKey: lastKey) {
                queue.swapAt(queue.count - 1, queue.count - 2)
            }
        }

        let next = queue.removeLast()
        defaults.set(queue, forKey: queueKey)
        defaults.set(next, forKey: lastKey)
        return UUID(uuidString: next) ?? candidates[0]
    }
}
