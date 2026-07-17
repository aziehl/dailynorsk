import SwiftData
import SwiftUI

struct ReviewView: View {
    let repository: ContentRepository
    let study: (LearningItem) -> Void

    @Query private var progressRecords: [LearningProgress]

    var body: some View {
        NavigationStack {
            List {
                if dueItems.isEmpty {
                    ContentUnavailableView {
                        Label("You’re caught up", systemImage: "checkmark.circle.fill")
                    } description: {
                        Text("Items you mark for review—and scheduled refreshers—will appear here.")
                    } actions: {
                        Button("Study today’s item") {
                            study(DailyContentSelector().item(for: .now, in: repository))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Section("Due now") {
                        ForEach(dueItems) { due in
                            Button {
                                study(due.item)
                            } label: {
                                ReviewDueRow(item: due.item, progress: due.progress)
                            }
                        }
                    }
                }

                if !upcomingItems.isEmpty {
                    Section("Coming up") {
                        ForEach(upcomingItems) { upcoming in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(upcoming.item.title)
                                    Text(upcoming.item.english)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let date = upcoming.progress.nextReviewAt {
                                    Text(date, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Review")
            .accessibilityIdentifier("reviewList")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(dueItems.count) due")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(dueItems.isEmpty ? Color.secondary : Color.orange)
                }
            }
        }
    }

    private var dueItems: [ReviewQueueItem] {
        progressRecords
            .filter { $0.isDue() }
            .compactMap { progress in
                repository.item(withID: progress.contentID).map {
                    ReviewQueueItem(item: $0, progress: progress)
                }
            }
            .sorted { lhs, rhs in
                (lhs.progress.nextReviewAt ?? .distantPast) < (rhs.progress.nextReviewAt ?? .distantPast)
            }
    }

    private var upcomingItems: [ReviewQueueItem] {
        progressRecords
            .filter { !$0.isDue() && $0.nextReviewAt != nil }
            .compactMap { progress in
                repository.item(withID: progress.contentID).map {
                    ReviewQueueItem(item: $0, progress: progress)
                }
            }
            .sorted {
                ($0.progress.nextReviewAt ?? .distantFuture) < ($1.progress.nextReviewAt ?? .distantFuture)
            }
            .prefix(5)
            .map { $0 }
    }
}

private struct ReviewQueueItem: Identifiable {
    let item: LearningItem
    let progress: LearningProgress

    var id: UUID { item.id }
}

private struct ReviewDueRow: View {
    let item: LearningItem
    let progress: LearningProgress

    private var iconName: String {
        item.kind == .word ? "textformat" : "quote.bubble.fill"
    }

    private var iconColor: Color {
        item.kind == .word ? .blue : .purple
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(item.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(progress.status == .review ? "Marked for review" : "Scheduled review")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
        }
    }
}
