import SwiftData
import SwiftUI

struct LibraryView: View {
    let repository: ContentRepository
    let study: (LearningItem) -> Void

    @Query private var progressRecords: [LearningProgress]
    @State private var searchText = ""
    @State private var kindFilter = LibraryKindFilter.all
    @State private var levelFilter = LibraryLevelFilter.all
    @State private var bandFilter = LibraryBandFilter.all
    @State private var statusFilter = LibraryStatusFilter.all
    @State private var partOfSpeechFilter: PartOfSpeech?
    @State private var topicFilter: String?
    @State private var packFilter: String?

    var body: some View {
        NavigationStack {
            List {
                if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    Section {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                LearningItemDetailView(
                                    item: item,
                                    repository: repository,
                                    study: study
                                )
                            } label: {
                                LibraryItemRow(item: item, status: status(for: item))
                            }
                        }
                    } header: {
                        Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                    }
                }
            }
            .navigationTitle("Library")
            .accessibilityIdentifier("libraryList")
            .searchable(text: $searchText, prompt: "Norwegian, English, inflection, or tag")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        filterPicker("Content", selection: $kindFilter)
                        filterPicker("Level", selection: $levelFilter)
                        filterPicker("Frequency band", selection: $bandFilter)
                        filterPicker("Learning status", selection: $statusFilter)
                        Picker("Part of speech", selection: $partOfSpeechFilter) {
                            Text("All parts of speech").tag(PartOfSpeech?.none)
                            ForEach(PartOfSpeech.allCases, id: \.self) { partOfSpeech in
                                Text(partOfSpeech.displayName).tag(Optional(partOfSpeech))
                            }
                        }
                        Picker("Topic", selection: $topicFilter) {
                            Text("All topics").tag(String?.none)
                            ForEach(topics, id: \.self) { topic in
                                Text(topic.replacingOccurrences(of: "-", with: " ").capitalized)
                                    .tag(Optional(topic))
                            }
                        }
                        Picker("Content pack", selection: $packFilter) {
                            Text("All content packs").tag(String?.none)
                            ForEach(repository.manifest.packs) { pack in
                                Text(pack.id.replacingOccurrences(of: "-", with: " ").capitalized)
                                    .tag(Optional(pack.id))
                            }
                        }
                        if filtersAreActive {
                            Divider()
                            Button("Clear filters", action: clearFilters)
                        }
                    } label: {
                        Label("Filters", systemImage: filtersAreActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityIdentifier("libraryFilters")
                }
            }
        }
    }

    private var progressByID: [UUID: LearningProgress] {
        Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.contentID, $0) })
    }

    private var filteredItems: [LearningItem] {
        repository.items.filter { item in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                item.searchText.localizedStandardContains(searchText)
            let matchesKind = kindFilter.matches(item)
            let matchesLevel = levelFilter.matches(item.level)
            let matchesBand = bandFilter.matches(item)
            let matchesStatus = statusFilter.matches(progressByID[item.id]?.status ?? .new)
            let matchesPartOfSpeech = partOfSpeechFilter == nil || item.partOfSpeech == partOfSpeechFilter
            let matchesTopic = topicFilter == nil || item.tags.contains(topicFilter ?? "")
            let matchesPack = packFilter == nil || repository.packID(for: item.id) == packFilter
            return matchesSearch && matchesKind && matchesLevel && matchesBand && matchesStatus &&
                matchesPartOfSpeech && matchesTopic && matchesPack
        }
    }

    private var filtersAreActive: Bool {
        kindFilter != .all || levelFilter != .all || bandFilter != .all || statusFilter != .all ||
            partOfSpeechFilter != nil || topicFilter != nil || packFilter != nil
    }

    private var topics: [String] {
        let levels = Set(CEFRLevel.allCases.map(\.rawValue))
        return Set(repository.items.flatMap(\.tags))
            .filter { !levels.contains($0) }
            .sorted()
    }

    private func status(for item: LearningItem) -> LearningStatus {
        progressByID[item.id]?.status ?? .new
    }

    private func filterPicker<Value: CaseIterable & Hashable & Identifiable & CustomStringConvertible>(
        _ title: String,
        selection: Binding<Value>
    ) -> some View where Value.AllCases: RandomAccessCollection {
        Picker(title, selection: selection) {
            ForEach(Value.allCases) { value in
                Text(value.description).tag(value)
            }
        }
    }

    private func clearFilters() {
        kindFilter = .all
        levelFilter = .all
        bandFilter = .all
        statusFilter = .all
        partOfSpeechFilter = nil
        topicFilter = nil
        packFilter = nil
    }
}

private struct LibraryItemRow: View {
    let item: LearningItem
    let status: LearningStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind == .word ? "textformat" : "quote.bubble.fill")
                .frame(width: 28, height: 28)
                .foregroundStyle(item.kind == .word ? .blue : .purple)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline)
                Text(item.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(item.metadata)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 5) {
                Text(item.level.rawValue)
                    .font(.caption2.weight(.bold))
                Image(systemName: status.symbolName)
                    .foregroundStyle(status.tint)
                    .accessibilityLabel(status.displayName)
            }
        }
        .padding(.vertical, 3)
    }
}

private enum LibraryKindFilter: String, CaseIterable, Identifiable, CustomStringConvertible {
    case all
    case words
    case phrases

    var id: Self { self }
    var description: String { rawValue.capitalized }

    func matches(_ item: LearningItem) -> Bool {
        switch self {
        case .all: true
        case .words: item.kind == .word
        case .phrases: item.kind == .phrase
        }
    }
}

private enum LibraryLevelFilter: String, CaseIterable, Identifiable, CustomStringConvertible {
    case all
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"

    var id: Self { self }
    var description: String { rawValue == "all" ? "All levels" : rawValue }

    func matches(_ level: CEFRLevel) -> Bool {
        self == .all || rawValue == level.rawValue
    }
}

private enum LibraryBandFilter: String, CaseIterable, Identifiable, CustomStringConvertible {
    case all
    case core500 = "core-500"
    case rank501To1000 = "rank-501-1000"
    case rank1001To1500 = "rank-1001-1500"
    case rank1501To2000 = "rank-1501-2000"
    case rank2001To2500 = "rank-2001-2500"

    var id: Self { self }
    var description: String {
        guard self != .all, let band = FrequencyBand(rawValue: rawValue) else { return "All bands" }
        return band.displayName
    }

    func matches(_ item: LearningItem) -> Bool {
        guard self != .all else { return true }
        guard case let .word(word) = item else { return false }
        return word.frequencyBand.rawValue == rawValue
    }
}

private enum LibraryStatusFilter: String, CaseIterable, Identifiable, CustomStringConvertible {
    case all
    case new
    case seen
    case learning
    case known
    case review

    var id: Self { self }
    var description: String { rawValue == "all" ? "All statuses" : rawValue.capitalized }

    func matches(_ status: LearningStatus) -> Bool {
        self == .all || rawValue == status.rawValue
    }
}
