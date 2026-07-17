import AVFAudio
import SwiftUI

@MainActor
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    private var isAudioSessionActive = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stop()
        errorMessage = nil

        guard let voice = AVSpeechSynthesisVoice(language: "nb-NO") else {
            errorMessage = "A Norwegian voice is not installed on this device."
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            // Recognition uses a record-only category. Explicitly restore a
            // spoken-audio playback session before asking the synthesizer to
            // render the next word or example.
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
            isAudioSessionActive = true
        } catch {
            errorMessage = "Norwegian audio could not be played. Please try again."
            deactivateSession()
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
        deactivateSession()
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
        deactivateSession()
    }

    private func deactivateSession() {
        guard isAudioSessionActive else { return }
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        isAudioSessionActive = false
    }
}
