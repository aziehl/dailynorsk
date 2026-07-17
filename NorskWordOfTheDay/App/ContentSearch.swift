import Foundation

extension ContentRepository {
    var items: [LearningItem] {
        words.map(LearningItem.word) + phrases.map(LearningItem.phrase)
    }
}

extension LearningItem {
    var tags: [String] {
        switch self {
        case let .word(word): word.tags
        case let .phrase(phrase): phrase.tags
        }
    }

    var partOfSpeech: PartOfSpeech? {
        guard case let .word(word) = self else { return nil }
        return word.partOfSpeech
    }

    var searchText: String {
        switch self {
        case let .word(word):
            return ([
                word.lemma,
                word.displayForm,
                word.englishDefinition,
                word.norwegianDefinition,
                word.exampleNorwegian,
                word.exampleEnglish,
            ].compactMap { $0 } + word.inflections + word.alternateMeanings +
                (word.regionalVariants ?? []).flatMap { [$0.form, $0.region, $0.note].compactMap { $0 } } +
                word.tags)
                .joined(separator: " ")
        case let .phrase(phrase):
            return ([
                phrase.norwegian,
                phrase.english,
                phrase.literalTranslation,
                phrase.usageNote,
                phrase.exampleNorwegian,
                phrase.exampleEnglish,
            ].compactMap { $0 } + phrase.alternateForms +
                (phrase.regionalVariants ?? []).flatMap { [$0.form, $0.region, $0.note].compactMap { $0 } } +
                phrase.tags)
                .joined(separator: " ")
        }
    }

    var metadata: String {
        switch self {
        case let .word(word):
            "\(word.partOfSpeech.displayName) • \(word.frequencyBand.displayName) • #\(word.rank)\(regionalSuffix)"
        case let .phrase(phrase):
            "\(phrase.type.displayName) • \(phrase.register.rawValue.capitalized)\(regionalSuffix)"
        }
    }

    private var regionalSuffix: String {
        tags.contains("vestland") || tags.contains("bergensk") ? " • Vestland" : ""
    }
}
