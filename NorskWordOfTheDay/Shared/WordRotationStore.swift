import Foundation

struct WordRotationStore {
    private let defaults: UserDefaults
    private let queueKey = "wordRotationQueue"
    private let datasetKey = "wordRotationDataset"

    init(defaults: UserDefaults = SharedDefaults.defaults) {
        self.defaults = defaults
    }

    mutating func nextWord(from words: [WordEntry]) -> WordEntry {
        precondition(!words.isEmpty, "Cannot rotate through an empty word list")

        let datasetSignature = words.map(\.id.uuidString).sorted().joined(separator: ",")
        var queue = defaults.stringArray(forKey: queueKey) ?? []

        if defaults.string(forKey: datasetKey) != datasetSignature {
            queue.removeAll()
            defaults.set(datasetSignature, forKey: datasetKey)
        }

        let wordsByID = Dictionary(uniqueKeysWithValues: words.map { ($0.id.uuidString, $0) })
        queue.removeAll { wordsByID[$0] == nil }

        if queue.isEmpty {
            queue = words.map(\.id.uuidString).shuffled()

            if queue.count > 1,
               queue.last == SharedDefaults.currentWord(in: words)?.id.uuidString {
                queue.swapAt(queue.count - 1, queue.count - 2)
            }
        }

        let nextID = queue.removeLast()
        defaults.set(queue, forKey: queueKey)
        return wordsByID[nextID] ?? words[0]
    }
}
