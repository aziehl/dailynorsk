import SwiftData
import SwiftUI
import WidgetKit

struct LearningView: View {
    let repository: ContentRepository
    @Binding var currentItem: LearningItem

    @StateObject private var speechService = SpeechService()
    @StateObject private var speechRecognitionService = SpeechRecognitionService()
    @State private var isRevealed = false
    @State private var preparedInitialItem = false
    @State private var previousItems: [LearningItem] = []
    @State private var persistenceError: String?
    @AppStorage("learningMode") private var learningModeValue = LearningMode.mixed.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [LearningProgress]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    dailyShortcut

                    Picker("Learning content", selection: learningModeBinding) {
                        ForEach(LearningMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    learningCard

                    HStack {
                        Button(action: showPreviousItem) {
                            Label("Previous", systemImage: "arrow.left.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(previousItems.isEmpty)
                        .accessibilityIdentifier("previousItemButton")

                        Button(action: showNextItem) {
                            Label(nextButtonTitle, systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("nextItemButton")
                    }
                }
                .padding()
                .safeAreaPadding(.bottom, 64)
            }
            .navigationTitle("Daily Norsk")
            .onAppear {
                guard !preparedInitialItem else { return }
                preparedInitialItem = true
                prepare(currentItem)
            }
            .onChange(of: currentItem) { _, item in
                prepare(item)
            }
            .alert("Progress wasn’t saved", isPresented: persistenceErrorBinding) {
                Button("OK", role: .cancel) { persistenceError = nil }
            } message: {
                Text(persistenceError ?? "Please try again.")
            }
            .onDisappear {
                speechRecognitionService.reset()
                speechService.stop()
            }
        }
    }

    private var dailyItem: LearningItem {
        DailyContentSelector().item(for: .now, in: repository)
    }

    private var dailyShortcut: some View {
        Button {
            navigate(to: dailyItem)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(dailyItem.kind == .word ? "Word of the day" : "Today’s Vestland phrase")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(dailyItem.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(dailyItem.english)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if currentItem.id == dailyItem.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens today’s scheduled learning card")
        .accessibilityIdentifier("dailyShortcut")
    }

    private var learningCard: some View {
        VStack(spacing: 15) {
            HStack {
                Label(
                    currentItem.kind == .word ? "Word" : "Phrase",
                    systemImage: currentItem.kind == .word ? "textformat" : "quote.bubble"
                )
                Spacer()
                if let progress = progressRecords.first(where: { $0.contentID == currentItem.id }) {
                    Text(progress.status.displayName)
                        .foregroundStyle(progress.status.tint)
                }
                Text(currentItem.level.rawValue)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)

            Text(currentItem.title)
                .font(.system(currentItem.kind == .word ? .largeTitle : .title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("learningItemTitle")

            Button {
                speak(currentItem.title)
            } label: {
                Label("Hear \(currentItem.kind.rawValue)", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("hearItemButton")

            Divider().padding(.vertical, 4)

            if isRevealed {
                revealedContent
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button("Tap to reveal") {
                    withAnimation(reduceMotion ? nil : .easeInOut) {
                        isRevealed = true
                    }
                }
                .font(.headline)
                .accessibilityHint("Shows the English translation, grammar, and example")
                .accessibilityIdentifier("revealButton")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 390, alignment: .top)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.quaternary, lineWidth: 1)
        }
        .alert("Audio unavailable", isPresented: speechErrorBinding) {
            Button("OK", role: .cancel) { speechService.dismissError() }
        } message: {
            Text(speechService.errorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private var revealedContent: some View {
        VStack(spacing: 14) {
            switch currentItem {
            case let .word(word): wordDetails(word)
            case let .phrase(phrase): phraseDetails(phrase)
            }

            PronunciationPracticeView(
                service: speechRecognitionService,
                target: currentItem.exampleNorwegian,
                alternatives: [],
                prepareToListen: speechService.stop,
                onAttempt: recordPronunciationAttempt
            )

            Divider()
            HStack {
                Button {
                    recordAssessment(known: false)
                } label: {
                    Label("Review again", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    recordAssessment(known: true)
                } label: {
                    Label("I knew this", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.caption.weight(.semibold))
        }
    }

    private func wordDetails(_ word: WordEntry) -> some View {
        VStack(spacing: 12) {
            Text(word.englishDefinition)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("translationText")

            if let definition = word.norwegianDefinition {
                Text(definition)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !word.inflections.isEmpty {
                Text(word.inflections.joined(separator: "  •  "))
                    .font(.callout.monospaced())
                    .multilineTextAlignment(.center)
            }

            regionalVariantSection(word.regionalVariants)

            example(word.exampleNorwegian, translation: word.exampleEnglish)
            audioButton(text: word.exampleNorwegian, label: "Hear example")

            let related = repository.relatedPhrases(for: word.id)
            if !related.isEmpty {
                Divider()
                Text("Related phrases")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TagFlowLayout(spacing: 8) {
                    ForEach(related.prefix(4)) { phrase in
                        Button(phrase.norwegian) { navigate(to: .phrase(phrase)) }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func phraseDetails(_ phrase: PhraseEntry) -> some View {
        VStack(spacing: 12) {
            Text(phrase.english)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("translationText")

            if let literal = phrase.literalTranslation,
               literal.localizedCaseInsensitiveCompare(phrase.english) != .orderedSame {
                Text("Literally: \(literal)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let usageNote = phrase.usageNote {
                Text(usageNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\(phrase.type.displayName) • \(phrase.register.rawValue.capitalized)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            regionalVariantSection(phrase.regionalVariants)

            example(phrase.exampleNorwegian, translation: phrase.exampleEnglish)
            audioButton(text: phrase.exampleNorwegian, label: "Hear in context")

            let words = phrase.focusWordIDs.compactMap(repository.word(withID:))
            if !words.isEmpty {
                Divider()
                Text("Focus words")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TagFlowLayout(spacing: 8) {
                    ForEach(words) { word in
                        Button(word.displayForm) { navigate(to: .word(word)) }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
            }

            Divider()
            PhrasePracticeView(phrase: phrase)
                .id(phrase.id)
        }
    }

    private func example(_ norwegian: String, translation: String) -> some View {
        VStack(spacing: 5) {
            Text(norwegian).font(.headline)
            Text(translation).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func regionalVariantSection(_ variants: [RegionalVariant]?) -> some View {
        if let variants, !variants.isEmpty {
            VStack(spacing: 7) {
                Label("Vestland speech", systemImage: "mountain.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(variants.enumerated()), id: \.offset) { _, variant in
                    VStack(spacing: 2) {
                        Text(variant.form)
                            .font(.headline)
                        Text(variant.region)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let note = variant.note {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func audioButton(text: String, label: String) -> some View {
        Button {
            speak(text)
        } label: {
            Label(label, systemImage: "text.bubble.fill")
        }
        .buttonStyle(.bordered)
    }

    private func speak(_ text: String) {
        speechRecognitionService.reset()
        speechService.speak(text)
    }

    private var learningMode: LearningMode {
        LearningMode(rawValue: learningModeValue) ?? .mixed
    }

    private var learningModeBinding: Binding<LearningMode> {
        Binding(
            get: { learningMode },
            set: { learningModeValue = $0.rawValue }
        )
    }

    private var nextButtonTitle: String {
        switch learningMode {
        case .mixed: "Next item"
        case .words: "Next word"
        case .phrases: "Next phrase"
        }
    }

    private func showNextItem() {
        var rotation = LearningRotationStore()
        navigate(to: rotation.nextItem(from: repository, mode: learningMode))
    }

    private func showPreviousItem() {
        guard let previous = previousItems.popLast() else { return }
        currentItem = previous
    }

    private func navigate(to item: LearningItem) {
        guard item.id != currentItem.id else { return }
        previousItems.append(currentItem)
        if previousItems.count > 100 {
            previousItems.removeFirst(previousItems.count - 100)
        }
        currentItem = item
    }

    private func prepare(_ item: LearningItem) {
        speechRecognitionService.reset()
        speechService.stop()
        var rotation = LearningRotationStore()
        rotation.markIntroduced(item)
        SharedDefaults.saveCurrentItem(item)
        recordSeen(item)
        WidgetCenter.shared.reloadAllTimelines()
        withAnimation(reduceMotion ? nil : .easeInOut) {
            isRevealed = false
        }
    }

    private func progress(for item: LearningItem) -> LearningProgress {
        if let existing = progressRecords.first(where: { $0.contentID == item.id }) {
            return existing
        }
        let progress = LearningProgress(contentID: item.id, contentKind: item.kind)
        modelContext.insert(progress)
        return progress
    }

    private func recordSeen(_ item: LearningItem) {
        if let existing = progressRecords.first(where: { $0.contentID == item.id }) {
            existing.recordSeen()
        } else {
            modelContext.insert(LearningProgress(contentID: item.id, contentKind: item.kind))
        }
        saveProgress()
    }

    private func recordAssessment(known: Bool) {
        let itemProgress = progress(for: currentItem)
        if known {
            itemProgress.recordKnown()
        } else {
            itemProgress.recordReview()
        }
        saveProgress()
        showNextItem()
    }

    private func recordPronunciationAttempt() {
        progress(for: currentItem).recordPronunciationAttempt()
        saveProgress()
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { persistenceError != nil },
            set: { if !$0 { persistenceError = nil } }
        )
    }

    private var speechErrorBinding: Binding<Bool> {
        Binding(
            get: { speechService.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    speechService.dismissError()
                }
            }
        )
    }

    private func saveProgress() {
        do {
            try modelContext.save()
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}

private struct TagFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? 320
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (CGSize(width: width, height: y + lineHeight), points)
    }
}
