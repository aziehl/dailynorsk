import Foundation

struct DailyContentSelector {
    private let calendar: Calendar
    private let referenceDate: Date

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? .distantPast
    }

    func item(for date: Date, in repository: ContentRepository) -> LearningItem {
        let day = dayIndex(for: date)
        let widgetPhrases = repository.phrases.filter(\.isWidgetEligible)

        if day.isMultiple(of: 5), !widgetPhrases.isEmpty {
            let phraseDay = day / 5
            return .phrase(select(widgetPhrases, position: phraseDay, id: \.id))
        }

        let wordDay = day - (day / 5)
        return .word(select(repository.words, position: wordDay, id: \.id))
    }

    private func dayIndex(for date: Date) -> Int {
        let start = calendar.startOfDay(for: referenceDate)
        let target = calendar.startOfDay(for: date)
        return max(0, calendar.dateComponents([.day], from: start, to: target).day ?? 0)
    }

    private func select<Value>(_ values: [Value], position: Int, id: KeyPath<Value, UUID>) -> Value {
        precondition(!values.isEmpty, "Daily selection requires at least one item")
        let cycle = position / values.count
        let index = position % values.count
        let ordered = values.sorted {
            stableHash("\(cycle):\($0[keyPath: id].uuidString)") <
                stableHash("\(cycle):\($1[keyPath: id].uuidString)")
        }
        return ordered[index]
    }

    private func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(14_695_981_039_346_656_037) { partial, byte in
            (partial ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
