import AppIntents
import SwiftUI
import WidgetKit

struct NorskWidgetEntry: TimelineEntry {
    let date: Date
    let item: LearningItem
}

struct NorskWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NorskWidgetEntry {
        NorskWidgetEntry(date: .now, item: Self.fallbackItem)
    }

    func getSnapshot(in context: Context, completion: @escaping (NorskWidgetEntry) -> Void) {
        completion(NorskWidgetEntry(date: .now, item: selectedItem(from: repository)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NorskWidgetEntry>) -> Void) {
        let calendar = Calendar.current
        guard let repository else {
            let retryDate = calendar.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3_600)
            completion(Timeline(entries: [NorskWidgetEntry(date: .now, item: Self.fallbackItem)], policy: .after(retryDate)))
            return
        }
        let selector = DailyContentSelector(calendar: calendar)
        let today = calendar.startOfDay(for: .now)
        var entries = [NorskWidgetEntry(date: .now, item: selectedItem(from: repository))]

        for offset in 1...14 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            entries.append(NorskWidgetEntry(date: date, item: selector.item(for: date, in: repository)))
        }

        let reloadDate = calendar.date(byAdding: .day, value: 14, to: today) ?? .now.addingTimeInterval(1_209_600)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private var repository: ContentRepository? {
        try? ContentRepository()
    }

    private func selectedItem(from repository: ContentRepository?) -> LearningItem {
        guard let repository else { return Self.fallbackItem }
        return SharedDefaults.widgetItem() ?? DailyContentSelector().item(for: .now, in: repository)
    }

    private static let fallbackItem = LearningItem.word(
        WordEntry(
            id: UUID(uuidString: "2FD8CE7B-CA3A-457C-B9B4-CE32F13D186C")!,
            rank: 1,
            teachingPriority: 1,
            frequencyBand: .core500,
            contentVersion: 1,
            level: .a1,
            lemma: "hei",
            displayForm: "hei",
            partOfSpeech: .interjection,
            englishDefinition: "hello",
            norwegianDefinition: nil,
            gender: nil,
            inflections: [],
            exampleNorwegian: "Hei!",
            exampleEnglish: "Hello!",
            alternateMeanings: [],
            regionalVariants: nil,
            tags: ["greeting"]
        )
    )
}

struct NorskWordWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NorskWidgetEntry

    private let norwayRed = Color(
        red: 186.0 / 255.0,
        green: 12.0 / 255.0,
        blue: 47.0 / 255.0
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.item.kind == .word ? "WORD OF THE DAY" : "VESTLANDSUTTRYKK")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))

            Text(entry.item.title)
                .font(.system(family == .systemSmall ? .title2 : .title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(family == .systemSmall ? 3 : 2)
                .minimumScaleFactor(0.68)

            Text(entry.item.english)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)

            if family != .systemSmall, let usageExample {
                VStack(alignment: .leading, spacing: 2) {
                    Text(usageExample.norwegian)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(family == .systemLarge ? 3 : 2)

                    Text(usageExample.english)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(family == .systemLarge ? 3 : 2)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()

                Button(intent: NextItemIntent()) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show another learning item")
            }
        }
        .widgetURL(URL(string: "norskword://\(entry.item.kind.rawValue)/\(entry.item.id.uuidString)"))
        .containerBackground(norwayRed, for: .widget)
    }

    private var metadata: String {
        switch entry.item {
        case let .word(word): word.partOfSpeech.displayName
        case let .phrase(phrase): phrase.type.displayName
        }
    }

    /// Older widget overrides can outlive a content update. Show only a
    /// complete bilingual source pair and never render a legacy definition
    /// template as a usage example.
    private var usageExample: (norwegian: String, english: String)? {
        let norwegian = entry.item.exampleNorwegian.trimmingCharacters(in: .whitespacesAndNewlines)
        let english = entry.item.exampleEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = "\(norwegian) \(english)".lowercased()
        let templateFragments = [
            "kan bety",
            "ordet ",
            "på engelsk",
            "can mean",
            "the word ",
            "means in english",
        ]

        guard !norwegian.isEmpty,
              !english.isEmpty,
              !templateFragments.contains(where: { combined.contains($0) }) else {
            return nil
        }
        return (norwegian, english)
    }
}

struct NorskWordWidget: Widget {
    let kind = "NorskWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NorskWidgetProvider()) { entry in
            NorskWordWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Norsk")
        .description("Learn useful Norwegian with Vestland and Bergen spoken forms.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    NorskWordWidget()
} timeline: {
    NorskWidgetEntry(date: .now, item: .word(WordRepository().words[0]))
}
