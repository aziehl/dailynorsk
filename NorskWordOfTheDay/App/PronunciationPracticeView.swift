import SwiftUI

struct PronunciationPracticeView: View {
    @ObservedObject var service: SpeechRecognitionService
    let target: String
    let alternatives: [String]
    let prepareToListen: () -> Void
    let onAttempt: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Speak this sentence")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(target)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.center)

            Button {
                if service.isListening {
                    service.stop()
                } else {
                    prepareToListen()
                    onAttempt()
                    service.start(target: target, alternatives: alternatives)
                }
            } label: {
                Label(
                    service.isListening ? "Stop listening" : "Check recognition",
                    systemImage: service.isListening ? "stop.circle.fill" : "mic.circle.fill"
                )
            }
            .buttonStyle(.bordered)
            .tint(service.isListening ? .red : .accentColor)
            .disabled(service.state == .requestingPermission || service.state == .processing)
            .accessibilityIdentifier("speechRecognitionButton")

            if !service.feedback.isEmpty {
                Text(service.feedback)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(service.feedback == "Heard correctly" ? .green : .secondary)
                    .multilineTextAlignment(.center)
            }

            if case let .unavailable(message) = service.state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("speechRecognitionStatus")
            }

            Text("The app does not save your recording. Recognition stays on device when supported; otherwise Apple processes the audio. This is not a pronunciation score.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
        .onChange(of: target) { _, _ in service.reset() }
        .onDisappear { service.reset() }
    }
}
