import SwiftData
import SwiftUI

struct LearningItemDetailView: View {
    let item: LearningItem
    let repository: ContentRepository
    let study: (LearningItem) -> Void

    @StateObject private var speechService = SpeechService()
    @Query private var progressRecords: [LearningProgress]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(item.kind.rawValue.capitalized, systemImage: item.kind == .word ? "textformat" : "quote.bubble")
                        Spacer()
                        Text(item.level.rawValue)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text(item.title)
                        .font(.largeTitle.bold())

                    Text(item.english)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Button {
                        speechService.speak(item.title)
                    } label: {
                        Label("Hear Norwegian", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }

            detailSections

            Section("Example") {
                Text(item.exampleNorwegian).font(.headline)
                Text(item.exampleEnglish).foregroundStyle(.secondary)
                Button {
                    speechService.speak(item.exampleNorwegian)
                } label: {
                    Label("Hear complete example", systemImage: "text.bubble.fill")
                }
            }

            if let progress = progressRecords.first(where: { $0.contentID == item.id }) {
                Section("Learning record") {
                    LabeledContent("Status", value: progress.status.displayName)
                    LabeledContent("Times seen", value: "\(progress.timesSeen)")
                    LabeledContent("Known answers", value: "\(progress.knownCount)")
                    LabeledContent("Review answers", value: "\(progress.reviewCount)")
                    if let nextReview = progress.nextReviewAt {
                        LabeledContent("Next review") {
                            Text(nextReview, style: .relative)
                        }
                    }
                }
            }

            Section {
                Button {
                    study(item)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.fill")
                        Text("Study this item")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 12))
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("studyItemButton")
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(item.kind == .word ? "Word" : "Phrase")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Audio unavailable", isPresented: speechErrorBinding) {
            Button("OK", role: .cancel) { speechService.dismissError() }
        } message: {
            Text(speechService.errorMessage ?? "Please try again.")
        }
        .onDisappear { speechService.stop() }
    }

    @ViewBuilder
    private var detailSections: some View {
        switch item {
        case let .word(word):
            if let norwegianDefinition = word.norwegianDefinition {
                Section("Norwegian explanation") {
                    Text(norwegianDefinition)
                }
            }
            regionalVariants(word.regionalVariants)
            Section("Grammar") {
                LabeledContent("Part of speech", value: word.partOfSpeech.displayName)
                if let gender = word.gender {
                    LabeledContent("Gender", value: gender.rawValue.capitalized)
                }
                if !word.inflections.isEmpty {
                    LabeledContent("Inflections") {
                        Text(word.inflections.joined(separator: " • "))
                            .multilineTextAlignment(.trailing)
                    }
                }
                LabeledContent("Frequency band", value: word.frequencyBand.displayName)
                LabeledContent("Source rank", value: "#\(word.rank)")
            }
            let related = repository.relatedPhrases(for: word.id)
            if !related.isEmpty {
                Section("Related phrases") {
                    ForEach(related) { phrase in
                        Button {
                            study(.phrase(phrase))
                        } label: {
                            VStack(alignment: .leading) {
                                Text(phrase.norwegian)
                                Text(phrase.english)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        case let .phrase(phrase):
            regionalVariants(phrase.regionalVariants)
            Section("Usage") {
                LabeledContent("Type", value: phrase.type.displayName)
                LabeledContent("Register", value: phrase.register.rawValue.capitalized)
                if let literal = phrase.literalTranslation,
                   literal.localizedCaseInsensitiveCompare(phrase.english) != .orderedSame {
                    LabeledContent("Literal note", value: literal)
                }
                if let note = phrase.usageNote {
                    Text(note)
                }
            }
            let words = phrase.focusWordIDs.compactMap(repository.word(withID:))
            if !words.isEmpty {
                Section("Focus words") {
                    ForEach(words) { word in
                        Button {
                            study(.word(word))
                        } label: {
                            VStack(alignment: .leading) {
                                Text(word.displayForm)
                                Text(word.englishDefinition)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func regionalVariants(_ variants: [RegionalVariant]?) -> some View {
        if let variants, !variants.isEmpty {
            Section("Vestland speech") {
                ForEach(Array(variants.enumerated()), id: \.offset) { _, variant in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(variant.form).font(.headline)
                        Text(variant.region).font(.caption).foregroundStyle(.secondary)
                        if let note = variant.note {
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
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
}
