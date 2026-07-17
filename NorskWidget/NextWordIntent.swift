import AppIntents
import WidgetKit

struct NextItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Show another Norwegian item"
    static let description = IntentDescription("Advances the widget to an unseen word or phrase.")

    func perform() async throws -> some IntentResult {
        let repository = try ContentRepository()
        var rotation = LearningRotationStore()
        let item = rotation.nextItem(from: repository, mode: .mixed)
        SharedDefaults.saveWidgetOverride(item)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
