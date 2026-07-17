import AVFAudio
import Foundation
import Speech

@MainActor
final class SpeechRecognitionService: ObservableObject {
    enum State: Equatable {
        case idle
        case requestingPermission
        case listening
        case processing
        case finished
        case unavailable(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var transcript = ""
    @Published private(set) var feedback = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb-NO"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var isInputTapInstalled = false
    private var isAudioSessionActive = false
    private var target = ""
    private var acceptedAlternatives: [String] = []

    var isListening: Bool { state == .listening }

    func start(target: String, alternatives: [String] = []) {
        stopAudio()
        self.target = target
        acceptedAlternatives = alternatives
        transcript = ""
        feedback = ""

#if targetEnvironment(simulator)
        // The Simulator can advertise a host microphone while its remote audio
        // component is unavailable. Attempting capture in that state produces
        // kAudioComponentErr_NotPermitted and invalid zero-byte buffers.
        state = .unavailable("Speech recognition requires a physical iPhone or iPad.")
#else
        state = .requestingPermission

        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            Task { @MainActor in
                guard let self else { return }
                guard speechStatus == .authorized else {
                    self.state = .unavailable("Speech recognition permission is not enabled.")
                    return
                }

                AVAudioApplication.requestRecordPermission { [weak self] isGranted in
                    Task { @MainActor in
                        guard let self else { return }
                        guard isGranted else {
                            self.state = .unavailable("Microphone permission is not enabled.")
                            return
                        }
                        self.beginRecognition()
                    }
                }
            }
        }
#endif
    }

    func stop() {
        guard isListening else { return }
        state = .processing
        request?.endAudio()
        stopCaptureAndDeactivateSession()
    }

    func reset() {
        stopAudio()
        transcript = ""
        feedback = ""
        state = .idle
    }

    private func beginRecognition() {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable("Norwegian speech recognition is currently unavailable.")
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            isAudioSessionActive = true
        } catch {
            state = .unavailable("The microphone could not be prepared.")
            return
        }

        guard session.isInputAvailable,
              session.sampleRate > 0,
              session.inputNumberOfChannels > 0 else {
            state = .unavailable("No microphone input is available.")
            stopAudio()
            return
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        recognitionRequest.contextualStrings = [target] + acceptedAlternatives
        request = recognitionRequest

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            state = .unavailable("No microphone input is available.")
            stopAudio()
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak recognitionRequest] buffer, _ in
            // Simulator route changes and interrupted hardware inputs can
            // briefly deliver an empty buffer. Speech rejects those buffers
            // and logs AVAudioBuffer mDataByteSize warnings, so discard them.
            guard buffer.frameLength > 0 else { return }
            let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
            guard !audioBuffers.isEmpty,
                  audioBuffers.allSatisfy({ audioBuffer in
                      audioBuffer.mData != nil && audioBuffer.mDataByteSize > 0
                  }) else {
                return
            }
            recognitionRequest?.append(buffer)
        }
        isInputTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            state = .unavailable("Recording could not start.")
            stopAudio()
            return
        }

        state = .listening
        task = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.updateFeedback()
                    if result.isFinal {
                        self.finishRecognition()
                    }
                }
                if error != nil {
                    if self.transcript.isEmpty {
                        self.state = .unavailable("No speech was recognized. Try again when it is quieter.")
                    } else {
                        self.finishRecognition()
                    }
                }
            }
        }
    }

    private func finishRecognition() {
        stopAudio()
        updateFeedback()
        state = transcript.isEmpty ? .unavailable("No speech was recognized.") : .finished
    }

    private func stopAudio() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        stopCaptureAndDeactivateSession()
    }

    private func stopCaptureAndDeactivateSession() {
        // Remove the tap first so no late empty buffers are forwarded while
        // the engine and audio route are shutting down.
        removeInputTap()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        guard isAudioSessionActive else { return }
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        isAudioSessionActive = false
    }

    private func removeInputTap() {
        guard isInputTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isInputTapInstalled = false
    }

    private func updateFeedback() {
        let heard = normalized(transcript)
        let targets = ([target] + acceptedAlternatives).map(normalized).filter { !$0.isEmpty }
        guard !heard.isEmpty else {
            feedback = "Listening…"
            return
        }

        if targets.contains(heard) {
            feedback = "Heard correctly"
        } else if targets.contains(where: { $0.contains(heard) || heard.contains($0) }) {
            feedback = "Almost recognized — we heard: \(transcript)"
        } else {
            feedback = "We heard: \(transcript)"
        }
    }

    private func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "nb-NO"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
