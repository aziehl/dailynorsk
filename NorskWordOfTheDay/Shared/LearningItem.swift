import Foundation

enum LearningItem: Identifiable, Hashable {
    case word(WordEntry)
    case phrase(PhraseEntry)

    var id: UUID {
        switch self {
        case let .word(word): word.id
        case let .phrase(phrase): phrase.id
        }
    }

    var kind: LearningItemKind {
        switch self {
        case .word: .word
        case .phrase: .phrase
        }
    }

    var title: String {
        switch self {
        case let .word(word): word.displayForm
        case let .phrase(phrase): phrase.norwegian
        }
    }

    var english: String {
        switch self {
        case let .word(word): word.englishDefinition
        case let .phrase(phrase): phrase.english
        }
    }

    var exampleNorwegian: String {
        switch self {
        case let .word(word): word.exampleNorwegian
        case let .phrase(phrase): phrase.exampleNorwegian
        }
    }

    var exampleEnglish: String {
        switch self {
        case let .word(word): word.exampleEnglish
        case let .phrase(phrase): phrase.exampleEnglish
        }
    }

    var level: CEFRLevel {
        switch self {
        case let .word(word): word.level
        case let .phrase(phrase): phrase.level
        }
    }
}

enum LearningItemKind: String, Codable, CaseIterable, Hashable {
    case word
    case phrase
}
