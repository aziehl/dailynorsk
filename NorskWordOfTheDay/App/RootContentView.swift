import SwiftUI

struct RootContentView: View {
    private let repository: ContentRepository?
    private let loadErrorDescription: String?
    @State private var selectedTab = AppTab.learn
    @State private var currentItem: LearningItem?

    init() {
        do {
            let repository = try ContentRepository()
            self.repository = repository
            loadErrorDescription = nil
            let launchURL = ProcessInfo.processInfo.arguments
                .first(where: { $0.hasPrefix("norskword://") })
                .flatMap(URL.init(string:))
            let launchItem = launchURL.flatMap { Self.item(from: $0, in: repository) }
            _currentItem = State(
                initialValue: launchItem ?? SharedDefaults.currentItem(in: repository) ?? .word(repository.words[0])
            )
        } catch {
            repository = nil
            loadErrorDescription = error.localizedDescription
            _currentItem = State(initialValue: nil)
        }
    }

    var body: some View {
        Group {
            if let repository, let item = currentItem {
                TabView(selection: $selectedTab) {
                    LearningView(repository: repository, currentItem: itemBinding(fallback: item))
                        .tabItem { Label("Learn", systemImage: "rectangle.stack.fill") }
                        .tag(AppTab.learn)

                    LibraryView(repository: repository, study: study)
                        .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                        .tag(AppTab.library)

                    ReviewView(repository: repository, study: study)
                        .tabItem { Label("Review", systemImage: "clock.arrow.circlepath") }
                        .tag(AppTab.review)

                    ProgressDashboardView(repository: repository)
                        .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                        .tag(AppTab.progress)
                }
            } else {
                ContentUnavailableView {
                    Label("Learning content unavailable", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(loadErrorDescription ?? "The bundled content could not be opened.")
                }
                .accessibilityIdentifier("contentLoadError")
            }
        }
        .onOpenURL(perform: openDeepLink)
    }

    private func study(_ item: LearningItem) {
        currentItem = item
        selectedTab = .learn
    }

    private func openDeepLink(_ url: URL) {
        guard let repository else { return }
        guard let item = Self.item(from: url, in: repository) else { return }
        study(item)
    }

    private func itemBinding(fallback: LearningItem) -> Binding<LearningItem> {
        Binding(
            get: { currentItem ?? fallback },
            set: { currentItem = $0 }
        )
    }

    private static func item(from url: URL, in repository: ContentRepository) -> LearningItem? {
        guard url.scheme == "norskword",
              ["word", "phrase"].contains(url.host),
              let id = UUID(uuidString: url.lastPathComponent) else {
            return nil
        }
        return repository.item(withID: id)
    }
}

private enum AppTab: Hashable {
    case learn
    case library
    case review
    case progress
}

#Preview {
    RootContentView()
}
