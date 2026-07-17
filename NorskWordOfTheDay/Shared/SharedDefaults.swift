import Foundation

enum SharedDefaults {
    static let appGroupIdentifier = "group.com.example.NorskWordOfTheDay"
    private static let currentWordIDKey = "currentWordID"
    private static let currentWordDataKey = "currentWordData"
    private static let currentItemIDKey = "currentItemID"
    private static let currentItemKindKey = "currentItemKind"
    private static let currentItemDataKey = "currentItemData"
    private static let widgetItemKindKey = "widgetItemKind"
    private static let widgetOverrideExpiresAtKey = "widgetOverrideExpiresAt"

    /// Use the shared suite only when this process actually has access to the
    /// App Group container. Unsigned tests and simulator launches can include
    /// the entitlement in the project without receiving a group container;
    /// asking CFPreferences for that unavailable suite produces noisy warnings
    /// and cannot share data with the widget anyway.
    static let defaults: UserDefaults = {
        // The checked-in identifier is intentionally a release placeholder.
        // Some OS versions return a nominal URL for it even though cfprefsd has
        // no registered container, so never open the suite until the publisher
        // replaces it with an App Group owned by the signing team.
        guard !appGroupIdentifier.contains(".example.") else {
            return .standard
        }
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil else {
            return .standard
        }
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }()

    static func saveCurrentWord(_ word: WordEntry) {
        defaults.set(word.id.uuidString, forKey: currentWordIDKey)
        saveCurrentItem(.word(word))
    }

    static func saveCurrentItem(_ item: LearningItem) {
        defaults.set(item.id.uuidString, forKey: currentItemIDKey)
        defaults.set(item.kind.rawValue, forKey: currentItemKindKey)

        if case let .word(word) = item {
            defaults.set(word.id.uuidString, forKey: currentWordIDKey)
        }
    }

    static func saveWidgetOverride(
        _ item: LearningItem,
        at date: Date = .now,
        calendar: Calendar = .current,
        store: UserDefaults = defaults
    ) {
        store.set(item.kind.rawValue, forKey: widgetItemKindKey)

        switch item {
        case let .word(word):
            store.set(try? JSONEncoder().encode(word), forKey: currentItemDataKey)
            store.set(try? JSONEncoder().encode(word), forKey: currentWordDataKey)
        case let .phrase(phrase):
            store.set(try? JSONEncoder().encode(phrase), forKey: currentItemDataKey)
        }

        let startOfToday = calendar.startOfDay(for: date)
        let expiration = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(86_400)
        store.set(expiration, forKey: widgetOverrideExpiresAtKey)
    }

    static func currentWord(in words: [WordEntry]) -> WordEntry? {
        guard let idString = defaults.string(forKey: currentWordIDKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }

        return words.first { $0.id == id }
    }

    static func widgetWord() -> WordEntry? {
        guard let data = defaults.data(forKey: currentWordDataKey) else {
            return nil
        }

        return try? JSONDecoder().decode(WordEntry.self, from: data)
    }

    static func currentItem(in repository: ContentRepository) -> LearningItem? {
        guard let idString = defaults.string(forKey: currentItemIDKey),
              let id = UUID(uuidString: idString) else {
            return currentWord(in: repository.words).map(LearningItem.word)
        }
        return repository.item(withID: id)
    }

    static func widgetItem(at date: Date = .now, store: UserDefaults = defaults) -> LearningItem? {
        guard let expiration = store.object(forKey: widgetOverrideExpiresAtKey) as? Date,
              date < expiration else {
            return nil
        }
        guard let kindValue = store.string(forKey: widgetItemKindKey),
              let kind = LearningItemKind(rawValue: kindValue),
              let data = store.data(forKey: currentItemDataKey) else {
            return nil
        }

        switch kind {
        case .word:
            return (try? JSONDecoder().decode(WordEntry.self, from: data)).map(LearningItem.word)
        case .phrase:
            return (try? JSONDecoder().decode(PhraseEntry.self, from: data)).map(LearningItem.phrase)
        }
    }
}
