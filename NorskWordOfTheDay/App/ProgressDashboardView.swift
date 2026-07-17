import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    let repository: ContentRepository

    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [LearningProgress]
    @State private var isConfirmingReset = false
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    overviewGrid
                    statusSection
                    levelSection
                    frequencySection
                    legalSection
                    databaseSection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .accessibilityIdentifier("progressDashboard")
            .confirmationDialog(
                "Reset all learning progress?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset progress", role: .destructive, action: resetProgress)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your bundled words and phrases will remain available.")
            }
            .alert("Progress couldn’t be reset", isPresented: persistenceErrorBinding) {
                Button("OK", role: .cancel) { persistenceError = nil }
            } message: {
                Text(persistenceError ?? "Please try again.")
            }
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardMetric(title: "Seen", value: seenCount, icon: "eye.fill", color: .blue)
            DashboardMetric(title: "Known", value: knownCount, icon: "checkmark.seal.fill", color: .green)
            DashboardMetric(title: "Due", value: dueCount, icon: "clock.badge.exclamationmark.fill", color: .orange)
            DashboardMetric(title: "Speech tries", value: pronunciationCount, icon: "waveform", color: .purple)
        }
    }

    private var statusSection: some View {
        DashboardSection(title: "Learning status") {
            VStack(spacing: 12) {
                ProgressBreakdownRow(title: "Words seen", value: seenWords, total: repository.words.count, tint: .blue)
                ProgressBreakdownRow(title: "Phrases seen", value: seenPhrases, total: repository.phrases.count, tint: .purple)
                ProgressBreakdownRow(title: "Words known", value: knownWords, total: repository.words.count, tint: .green)
                ProgressBreakdownRow(title: "Phrases known", value: knownPhrases, total: repository.phrases.count, tint: .mint)
            }
        }
    }

    private var levelSection: some View {
        DashboardSection(title: "Seen by level") {
            VStack(spacing: 12) {
                ForEach(CEFRLevel.allCases, id: \.self) { level in
                    let items = repository.items.filter { $0.level == level }
                    if !items.isEmpty {
                        ProgressBreakdownRow(
                            title: level.rawValue,
                            value: items.filter { progressByID[$0.id] != nil }.count,
                            total: items.count,
                            tint: .indigo
                        )
                    }
                }
            }
        }
    }

    private var frequencySection: some View {
        DashboardSection(title: "Word frequency bands") {
            VStack(spacing: 12) {
                ForEach(FrequencyBand.allCases, id: \.self) { band in
                    let words = repository.words.filter { $0.frequencyBand == band }
                    if !words.isEmpty {
                        ProgressBreakdownRow(
                            title: band.displayName,
                            value: words.filter { progressByID[$0.id] != nil }.count,
                            total: words.count,
                            tint: .teal
                        )
                    }
                }
            }
        }
    }

    private var databaseSection: some View {
        DashboardSection(title: "Local database") {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Progress records", value: "\(progressRecords.count)")
                LabeledContent("Bundled items", value: "\(repository.items.count)")
                Text("Learning history is stored locally with SwiftData. Definitions and translations are versioned, validated resources that work offline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Reset learning progress", role: .destructive) {
                    isConfirmingReset = true
                }
            }
        }
    }

    private var legalSection: some View {
        DashboardSection(title: "About") {
            NavigationLink {
                AboutAndPrivacyView(repository: repository)
            } label: {
                Label("Privacy, terms, and acknowledgements", systemImage: "hand.raised.fill")
            }
            .accessibilityIdentifier("aboutPrivacyLink")
        }
    }

    private var progressByID: [UUID: LearningProgress] {
        Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.contentID, $0) })
    }

    private var seenCount: Int { progressRecords.count }
    private var knownCount: Int { progressRecords.filter { $0.status == .known }.count }
    private var dueCount: Int { progressRecords.filter { $0.isDue() }.count }
    private var pronunciationCount: Int { progressRecords.reduce(0) { $0 + $1.pronunciationAttempts } }
    private var seenWords: Int { progressRecords.filter { $0.contentKind == .word }.count }
    private var seenPhrases: Int { progressRecords.filter { $0.contentKind == .phrase }.count }
    private var knownWords: Int { progressRecords.filter { $0.contentKind == .word && $0.status == .known }.count }
    private var knownPhrases: Int { progressRecords.filter { $0.contentKind == .phrase && $0.status == .known }.count }

    private func resetProgress() {
        progressRecords.forEach(modelContext.delete)
        do {
            try modelContext.save()
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { persistenceError != nil },
            set: { if !$0 { persistenceError = nil } }
        )
    }
}

private struct DashboardMetric: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            Text("\(value)")
                .font(.title.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct DashboardSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct ProgressBreakdownRow: View {
    let title: String
    let value: Int
    let total: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value) / \(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(value), total: Double(max(total, 1)))
                .tint(tint)
        }
    }
}

extension LearningStatus {
    var displayName: String {
        switch self {
        case .new: "New"
        case .seen: "Seen"
        case .learning: "Learning"
        case .known: "Known"
        case .review: "Review"
        }
    }

    var symbolName: String {
        switch self {
        case .new: "circle"
        case .seen: "eye.circle.fill"
        case .learning: "ellipsis.circle.fill"
        case .known: "checkmark.circle.fill"
        case .review: "arrow.counterclockwise.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .new: .secondary
        case .seen: .blue
        case .learning: .indigo
        case .known: .green
        case .review: .orange
        }
    }
}
