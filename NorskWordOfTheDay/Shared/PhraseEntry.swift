import Foundation

struct PhraseEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let teachingPriority: Int
    let contentVersion: Int
    let level: CEFRLevel
    let norwegian: String
    let english: String
    let literalTranslation: String?
    let usageNote: String?
    let type: PhraseType
    let register: PhraseRegister
    let componentWordIDs: [UUID]
    let focusWordIDs: [UUID]
    let exampleNorwegian: String
    let exampleEnglish: String
    let alternateForms: [String]
    let regionalVariants: [RegionalVariant]?
    let slots: [PhraseSlot]
    let isStandalone: Bool
    let isWidgetEligible: Bool
    let tags: [String]
}

enum PhraseType: String, Codable, CaseIterable, Hashable {
    case collocation
    case fixedExpression = "fixed-expression"
    case conversationalFrame = "conversational-frame"
    case particleVerb = "particle-verb"
    case idiom
    case proverb
    case slang
    case sentenceStem = "sentence-stem"

    var displayName: String {
        switch self {
        case .collocation: "Collocation"
        case .fixedExpression: "Fixed expression"
        case .conversationalFrame: "Conversational frame"
        case .particleVerb: "Particle verb"
        case .idiom: "Idiom"
        case .proverb: "Proverb"
        case .slang: "Slang"
        case .sentenceStem: "Sentence stem"
        }
    }
}

enum PhraseRegister: String, Codable, CaseIterable, Hashable {
    case neutral
    case informal
    case formal
}

struct PhraseSlot: Codable, Hashable {
    let marker: String
    let description: String
    let examples: [String]
}
