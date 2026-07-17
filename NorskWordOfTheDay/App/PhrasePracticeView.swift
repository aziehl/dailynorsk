import SwiftUI

struct PhrasePracticeView: View {
    let phrase: PhraseEntry

    @State private var availableTokens: [BuilderToken]
    @State private var selectedTokens: [BuilderToken] = []
    @State private var builderFeedback = ""
    @State private var slotSelections: [Int: String] = [:]
    @State private var selectedVariant: String

    init(phrase: PhraseEntry) {
        self.phrase = phrase
        let tokens = Self.tokens(in: phrase.norwegian)
        _availableTokens = State(initialValue: tokens.shuffled())
        _selectedVariant = State(initialValue: phrase.norwegian)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            phraseBuilder
            if !phrase.slots.isEmpty {
                Divider()
                slotPractice
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var phraseBuilder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Build the phrase", systemImage: "square.grid.3x3.fill")
                .font(.headline)
            Text("Tap the words in their natural order. Punctuation stays attached to its word.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if practiceVariants.count > 1 {
                Picker("Practice wording", selection: $selectedVariant) {
                    ForEach(practiceVariants, id: \.self) { variant in
                        Text(variant).tag(variant)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedVariant) { _, _ in resetBuilder() }
                .accessibilityIdentifier("phraseVariantPicker")
            }

            Button {
                undoLastToken()
            } label: {
                Text(selectedTokens.isEmpty ? "Your phrase appears here" : selectedTokens.map(\.text).joined(separator: " "))
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .disabled(selectedTokens.isEmpty)
            .accessibilityHint("Removes the last selected word")
            .accessibilityIdentifier("phraseBuilderAnswer")

            PhraseTokenFlowLayout(spacing: 8) {
                ForEach(availableTokens) { token in
                    Button {
                        select(token)
                    } label: {
                        Text(token.text)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.bordered)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityIdentifier("phraseBuilderToken_\(token.id)")
                }
            }

            HStack {
                Button("Shuffle", action: resetBuilder)
                    .disabled(selectedTokens.isEmpty && availableTokens.count < 2)
                Spacer()
                Button("Check order", action: checkBuilder)
                    .buttonStyle(.borderedProminent)
                    .disabled(!availableTokens.isEmpty || correctTokens.count < 2)
                    .accessibilityIdentifier("checkPhraseOrder")
            }

            if !builderFeedback.isEmpty {
                Label(
                    builderFeedback,
                    systemImage: builderFeedback == "Correct order" ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(builderFeedback == "Correct order" ? .green : .orange)
                .accessibilityIdentifier("phraseBuilderFeedback")
            }
        }
    }

    private var slotPractice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Try a phrase slot", systemImage: "rectangle.and.pencil.and.ellipsis")
                .font(.headline)
            Text("Each option is a documented natural substitution, so this practice does not reject valid variants.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(phrase.slots.enumerated()), id: \.offset) { index, slot in
                VStack(alignment: .leading, spacing: 8) {
                    Text(slot.description)
                        .font(.subheadline.weight(.semibold))
                    Text(slotPrompt(for: slot))
                        .font(.body.monospaced())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(slot.examples, id: \.self) { example in
                                Button(example) {
                                    slotSelections[index] = example
                                }
                                .buttonStyle(.bordered)
                                .tint(slotSelections[index] == example ? .accentColor : .secondary)
                            }
                        }
                    }

                    if let selection = slotSelections[index] {
                        Text(completedPhrase(slot: slot, selection: selection))
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Completed phrase: \(completedPhrase(slot: slot, selection: selection))")
                    }
                }
            }
        }
    }

    private func select(_ token: BuilderToken) {
        availableTokens.removeAll { $0.id == token.id }
        selectedTokens.append(token)
        builderFeedback = ""
    }

    private func undoLastToken() {
        guard let token = selectedTokens.popLast() else { return }
        availableTokens.append(token)
        builderFeedback = ""
    }

    private func resetBuilder() {
        availableTokens = correctTokens.shuffled()
        selectedTokens.removeAll()
        builderFeedback = ""
    }

    private func checkBuilder() {
        builderFeedback = selectedTokens.map(\.id) == correctTokens.map(\.id)
            ? "Correct order"
            : "Try another order"
    }

    private var practiceVariants: [String] {
        ([phrase.norwegian] + phrase.alternateForms + (phrase.regionalVariants ?? []).map(\.form))
            .reduce(into: []) { variants, variant in
            if !variants.contains(variant) {
                variants.append(variant)
            }
        }
    }

    private var correctTokens: [BuilderToken] {
        Self.tokens(in: selectedVariant)
    }

    private static func tokens(in text: String) -> [BuilderToken] {
        text.split(whereSeparator: \Character.isWhitespace)
            .enumerated()
            .map { BuilderToken(id: $0.offset, text: String($0.element)) }
    }

    private func slotPrompt(for slot: PhraseSlot) -> String {
        phrase.norwegian.replacingOccurrences(of: slot.marker, with: "_____")
    }

    private func completedPhrase(slot: PhraseSlot, selection: String) -> String {
        phrase.norwegian.replacingOccurrences(of: slot.marker, with: selection)
    }
}

private struct BuilderToken: Identifiable, Hashable {
    let id: Int
    let text: String
}

/// Places each token at its intrinsic width, moving the complete button to a
/// new line when the next token would exceed the available width.
private struct PhraseTokenFlowLayout: Layout {
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
        let availableWidth = proposal.width ?? 320
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > availableWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: availableWidth, height: y + lineHeight), points)
    }
}
