# Third-party notices

The distributed iOS app contains no third-party SDKs or bundled source repositories. Its expanded offline lexicon includes adapted dictionary text from English Wiktionary and translated example pairs from Tatoeba as described below. The curated Vestland phrase pack remains project-authored.

The source workspace includes two pinned Git submodules used only by the offline candidate-generation and editorial workflow. They are not added to either Xcode target and are not copied into the app or widget bundle.

## wordfreq

- Project: `wordfreq`
- Author and required credit: Robyn Speer
- Upstream: <https://github.com/rspeer/wordfreq>
- Pinned revision: `912caf64b657478d1dff1138efdc078947d54bb1`
- Code license: Apache License 2.0
- Included upstream data: Creative Commons Attribution-ShareAlike 4.0 plus the source-specific notices in upstream `NOTICE.md`
- Local license files: `References/wordfreq/LICENSE.txt` and `References/wordfreq/NOTICE.md`

No `wordfreq` code or raw dataset is shipped. The generated lexicon’s ordering and source-rank provenance are derived from its Norwegian frequency evidence and are included in the CC BY-SA 4.0 generated content pack with the attribution above and the source-specific credits in upstream `NOTICE.md`.

## Universal Dependencies Norwegian Bokmål

- Project: Universal Dependencies Norwegian Bokmål
- Upstream: <https://github.com/UniversalDependencies/UD_Norwegian-Bokmaal>
- Pinned revision: `396d11f0c2bd290a2a2711015c04ac25bc3dcc06`
- License: Creative Commons Attribution-ShareAlike 4.0 International
- Local license file: `References/ud-norwegian-bokmaal/LICENSE.txt`

The treebank is used as evidence for lemma/POS selection, morphology, and recurring sequence candidates. Generated lemma/POS selections are included in the CC BY-SA 4.0 content pack. The repository and its corpus sentences are not shipped in the app.

## English Wiktionary Norwegian Bokmål entries

- Work: Norwegian Bokmål dictionary entries from English Wiktionary contributors
- Source: <https://en.wiktionary.org/>
- Machine-readable extraction: Kaikki.org / `wiktextract`
- Extraction landing page: <https://kaikki.org/dictionary/Norwegian%20Bokm%C3%A5l/index.html>
- Wiktionary dump date: 6 July 2026
- Kaikki extraction date: 9 July 2026
- License: Creative Commons Attribution-ShareAlike 4.0 International
- License: <https://creativecommons.org/licenses/by-sa/4.0/>
- Contributor and revision history: use the History link on each linked Wiktionary entry

Daily Norsk adapts English glosses, inflection data, and a limited set of contributor examples into its generated lexical entries. The selection, JSON schema, ranking, labels, and dictionary-style gloss formatting are modifications. The Wiktionary-derived portion of `NorskWordOfTheDay/Resources/words.json` is distributed under CC BY-SA 4.0. The app’s About & Privacy screen provides attribution, source, license, and modification notice without implying endorsement by Wikimedia, Wiktionary contributors, Kaikki.org, or the `wiktextract` authors.

The source export is checksum-pinned in `ContentPipeline/Config/wiktionary-source.json`. It is not copied wholesale into the product; only promoted fields in the shipping word pack are bundled.

## Tatoeba Norwegian Bokmål–English sentence pairs

- Work: Norwegian Bokmål and English sentences contributed to Tatoeba
- Source and downloads: <https://tatoeba.org/en/downloads>
- Export date: 11 July 2026
- License: Creative Commons Attribution 2.0 France
- License: <https://creativecommons.org/licenses/by/2.0/fr/>
- Attribution: each promoted pair retains its Norwegian and English sentence IDs and contributor names in the release evidence; the Tatoeba sentence URLs derived from those IDs provide the corresponding public attribution and revision record.

Daily Norsk selects and pairs existing Tatoeba translations with its generated word entries. Selection, safety filtering, ranking, labels, and JSON integration are modifications. The source exports are checksum-pinned in `ContentPipeline/Config/tatoeba-source.json`; raw exports are not bundled in the app.

## Apple frameworks and standard agreement

SwiftUI, SwiftData, WidgetKit, Speech, AVFAudio, AppIntents, and XCTest are Apple platform frameworks and are not redistributed as third-party packages by this repository. Unless the App Store listing supplies a custom license, Apple’s standard Licensed Application End User License Agreement applies to the app: <https://www.apple.com/legal/internet-services/itunes/dev/stdeula/>.
