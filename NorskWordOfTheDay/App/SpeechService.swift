import AVFAudio
import SwiftUI

@MainActor
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?

    override init() {
        super.init()
        // Recording is the only feature that needs the app's shared audio
        // session. Let the system give synthesized speech its own managed
        // session so a recently stopped microphone route cannot leave the
        // synthesizer attached to the record-only session.
        synthesizer.usesApplicationAudioSession = false
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stop()
        errorMessage = nil

        guard let voice = AVSpeechSynthesisVoice(language: "nb-NO") else {
            errorMessage = "A Norwegian voice is not installed on this device."
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.42
        activeUtterance = utterance
        synthesizer.speak(utterance)
    }

    func stop() {
        // Clear identity before cancellation so its delayed delegate callback
        // cannot deactivate a newer utterance's audio session.
        activeUtterance = nil
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finish(utterance)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finish(utterance)
        }
    }

    private func finish(_ utterance: AVSpeechUtterance) {
        guard activeUtterance === utterance else { return }
        activeUtterance = nil
    }
}
