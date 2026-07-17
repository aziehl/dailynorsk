import Foundation

struct ContentManifest: Codable, Hashable {
    let schemaVersion: Int
    let contentVersion: String
    let language: String
    let packs: [ContentPack]
}

struct ContentPack: Codable, Identifiable, Hashable {
    let id: String
    let kind: LearningItemKind
    let version: Int
    let resource: String
    let itemCount: Int
    let minimumFrequencyRank: Int?
    let maximumFrequencyRank: Int?
}
