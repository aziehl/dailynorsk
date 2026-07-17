import Foundation

struct WordEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let rank: Int
    let teachingPriority: Int
    let frequencyBand: FrequencyBand
    let contentVersion: Int
    let level: CEFRLevel
    let lemma: String
    let displayForm: String
    let partOfSpeech: PartOfSpeech
    let englishDefinition: String
    let norwegianDefinition: String?
    let gender: NounGender?
    let inflections: [String]
    let exampleNorwegian: String
    let exampleEnglish: String
    let alternateMeanings: [String]
    let regionalVariants: [RegionalVariant]?
    let tags: [String]
}

struct RegionalVariant: Codable, Hashable {
    let form: String
    let region: String
    let note: String?
}

enum FrequencyBand: String, Codable, CaseIterable, Hashable {
    case core500 = "core-500"
    case rank501To1000 = "rank-501-1000"
    case rank1001To1500 = "rank-1001-1500"
    case rank1501To2000 = "rank-1501-2000"
    case rank2001To2500 = "rank-2001-2500"

    var displayName: String {
        switch self {
        case .core500: "Core 500"
        case .rank501To1000: "Words 501–1,000"
        case .rank1001To1500: "Words 1,001–1,500"
        case .rank1501To2000: "Words 1,501–2,000"
        case .rank2001To2500: "Words 2,001–2,500"
        }
    }
}

enum CEFRLevel: String, Codable, CaseIterable, Hashable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
}

enum PartOfSpeech: String, Codable, CaseIterable, Hashable {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case preposition
    case conjunction
    case determiner
    case interjection
    case numeral

    var displayName: String {
        rawValue.capitalized
    }
}

enum NounGender: String, Codable, Hashable {
    case masculine
    case feminine
    case neuter
}
