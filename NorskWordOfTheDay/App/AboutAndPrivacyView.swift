import SwiftUI

struct AboutAndPrivacyView: View {
    let repository: ContentRepository

    var body: some View {
        List {
            Section("About") {
                LabeledContent("App", value: "Daily Norsk")
                LabeledContent("Version", value: versionDescription)
                LabeledContent("Content pack", value: repository.manifest.contentVersion)
                Text("An offline-first Norwegian vocabulary and phrase-learning app focused on Vestland, with clearly labeled Bergen and western spoken alternatives alongside standard written forms.")
            }

            Section("Vestland focus") {
                Text("Norwegian dialects vary from place to place. Daily Norsk highlights useful Vestland speech and common Bergen forms such as ka, kor, kordan, and koffer without presenting one spelling as the only correct dialect form.")
                Text("Dialect spellings represent speech and are labeled by region. Use the standard Bokmål or Nynorsk form when formal written Norwegian is required.")
            }

            Section("Privacy policy") {
                Text("Daily Norsk has no accounts, advertising, analytics, tracking, cloud sync, or developer-operated server. The publisher does not receive your learning history, searches, speech transcripts, or device identifiers.")

                Text("Learning progress is stored locally with SwiftData. Widget selection and rotation state are stored in the app’s private App Group container. You can erase learning progress from the Progress screen, and deleting the app removes its local app data subject to normal device backup behavior.")

                Text("Speech practice is optional and starts only after you tap Check recognition and grant microphone and speech-recognition access. The app does not save audio recordings. Recognition remains on the device when the installed Norwegian recognizer supports it; otherwise the audio is sent to Apple’s speech-recognition service for the immediate request. The publisher does not receive the audio or transcript.")

                Text("You can revoke microphone or speech-recognition access at any time in iOS Settings. Because the publisher does not operate an account or collect personal data, there is no publisher-held account data to request or delete. Contact the publisher through the Support link on the app’s App Store page with privacy questions.")

                Link("Apple Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            }

            Section("Terms") {
                Text("The app is an educational aid. Translations, definitions, examples, speech transcripts, and review schedules may contain errors and are not professional, legal, medical, or safety advice.")
                Text("Unless the App Store listing expressly provides a custom agreement, Apple’s standard Licensed Application End User License Agreement governs use of the app.")
                Link(
                    "Apple Standard EULA",
                    destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
                )
            }

            Section("Acknowledgements") {
                Text("Daily Norsk contains project-authored Vestland lessons plus an expanded offline lexicon adapted from English Wiktionary contributors. Wiktionary-derived definitions and inflections are modified and distributed under the Creative Commons Attribution-ShareAlike 4.0 International license.")
                Link("English Wiktionary contributors", destination: URL(string: "https://en.wiktionary.org/wiki/Wiktionary:Copyrights")!)
                Link("Norwegian Bokmål extraction by Kaikki.org", destination: URL(string: "https://kaikki.org/dictionary/Norwegian%20Bokm%C3%A5l/index.html")!)
                Link("CC BY-SA 4.0", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
                Text("Most generated example pairs are selected from Tatoeba’s Norwegian Bokmål–English corpus. Daily Norsk preserves the sentence, contributor, and revision identifiers in its release evidence and credits Tatoeba under the Creative Commons Attribution 2.0 France license.")
                Link("Tatoeba contributors", destination: URL(string: "https://tatoeba.org/en/downloads")!)
                Link("CC BY 2.0 France", destination: URL(string: "https://creativecommons.org/licenses/by/2.0/fr/")!)
                Text("Frequency ordering and lemma/part-of-speech selection incorporate attributed wordfreq and Universal Dependencies evidence. Their repositories and raw source corpora are not included in the app binary; the generated lexical adaptations are covered by the content pack’s CC BY-SA 4.0 terms.")
                Link("wordfreq by Robyn Speer", destination: URL(string: "https://github.com/rspeer/wordfreq")!)
                Link(
                    "Universal Dependencies Norwegian Bokmål",
                    destination: URL(string: "https://github.com/UniversalDependencies/UD_Norwegian-Bokmaal")!
                )
                Text("Curated Vestland and Bergen speech forms were cross-checked against dialect descriptions and remain clearly labeled apart from standard Bokmål entries.")
                Link("Store norske leksikon: Bergen bymål", destination: URL(string: "https://snl.no/Bergen_bym%C3%A5l")!)
            }
        }
        .navigationTitle("About & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("aboutPrivacyScreen")
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
