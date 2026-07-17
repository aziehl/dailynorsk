import SwiftUI
import SwiftData

@main
struct NorskWordOfTheDayApp: App {
    var body: some Scene {
        WindowGroup {
            RootContentView()
        }
        .modelContainer(for: LearningProgress.self)
    }
}
