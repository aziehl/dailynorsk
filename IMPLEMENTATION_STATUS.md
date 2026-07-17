# Implementation status

This is the handoff record for the step-by-step plan. It distinguishes completed engineering from work that requires an Apple developer account, linguistic judgment, user testing, or release operations.

## Completed engineering

- Native SwiftUI app, WidgetKit extension, shared scheme, and XCTest target.
- Stable, versioned `WordEntry` and `PhraseEntry` schemas with a content-pack manifest.
- Strict bundled-content loading and validation for schema, language, packs, counts, IDs, ranks, teaching priorities, versions, and phrase cross-references, with an in-app error state and a safe widget fallback.
- Word, phrase, and mixed learning modes with separate shuffled queues, a four-word/one-phrase mix, and focus-word prerequisites.
- Word-to-phrase and phrase-to-word navigation, bounded previous-card history, reveal controls, speech playback, Reduce Motion handling, and literal/register labels.
- Four-tab main interface for learning, library discovery, due reviews, and progress.
- Indexed item and relationship lookups plus search across Norwegian, English translations, definitions, examples, inflections, alternate forms, and tags, with type, level, frequency-band, content-pack, part-of-speech, topic, and status filters.
- SwiftData progress keyed by stable content ID and content kind, with durable review scheduling, due/upcoming queues, separate word/phrase summaries, and safe reset.
- Progress dashboards by content type, status, CEFR level, and frequency band, with compact local-storage details.
- Phrase ordering practice, documented alternate-form selection, and natural slot-substitution practice without claiming that other valid Norwegian variants are wrong.
- A structured Vestland/Bergen speech layer with searchable regional forms, region and usage notes, dedicated card/detail presentation, and explicit separation from standard written Bokmål/Nynorsk.
- Dedicated slang and proverb lesson types with register, literal translations, present-day usage notes, cross-linked focus vocabulary, phrase ordering practice, speech playback, search, and widget eligibility.
- Deterministic local-day selection for words and widget-eligible phrases, 14-day widget timelines, exact deep links, translated small/medium layouts, independently accessible widget controls, safe content failure recovery, and manual widget advancement that expires at the next local midnight.
- `nb-NO` speech recognition practice with permission/error states and recognition feedback that is explicitly not a pronunciation score; microphone-route validation, empty-buffer filtering, and balanced audio-session teardown protect simulator and interrupted-input cases.
- A reproducible candidate pipeline combining pinned frequency evidence with Bokmål lemma, morphology, corpus-sequence evidence, and versioned Vestland/Bergen regional suggestions that are automatically flagged for local review.
- Git submodules under `References/`, preserving pinned commit links and upstream URLs so later revisions can be fetched deliberately.
- A native app icon asset catalog and UI automation for reveal, translation, deep-link selection, library search, study navigation, Review, and Progress.
- App and widget privacy manifests, export-compliance declarations, accurate speech-processing disclosures, an in-app privacy/terms/acknowledgements screen, and a versioned App Store submission packet.
- A root proprietary license for project-authored material plus an explicit CC BY-SA 4.0 exception for generated lexical adaptations, with separate content-rights and third-party licensing ledgers; raw source repositories and corpora remain excluded from distributed binaries.
- A deterministic `Scripts/release_preflight.sh` gate that reports content-size, identifier, signing, editorial sign-off, and hosted-URL blockers before submission.
- A reproducible 1,500-word shipping-lexicon builder that combines the pinned frequency/UD submodules with checksum-pinned English Wiktionary dictionary evidence and Tatoeba sentence pairs, stable IDs, generated provenance, in-app attribution, CC BY-SA 4.0, and CC BY 2.0 France handling.

## Current content boundary

- Bundled pre-release pack: 1,500 words and 42 phrases. The 32 hand-curated words include Vestland/Bergen question forms, Bergen and nationwide slang, and proverb-linked vocabulary; 1,468 attributed frequency entries supply the expanded offline lexicon.
- Generated review set: 2,763 lemma candidates from the top 5,000 frequency tokens. The 2026.07.5 pack rejects template “can mean” examples and only promotes a generated entry when it has a source-backed Norwegian–English example pair.
- Useful lexical review pool through raw rank 2,500: 1,292 candidates before editorial acceptance.
- Generated phrase-review set: 2,000 recurring 2–5-token corpus sequences.

Generated reports and full source dumps are deliberately ignored by Git and are never loaded by the app. The shipping JSON contains the promoted lexical fields, while the generated evidence report retains source links and review provenance. A fluent Norwegian editor should continue verifying senses, naturalness, translation, register, inflections, examples, and phrase usefulness in editorial bands.

## Still requires external or editorial work

1. Configure real bundle identifiers, a signing team, and a registered App Group in both targets.
2. Confirm the legal seller/copyright holder, create a working support page, and host the prepared privacy policy at a public HTTPS URL.
3. Complete fluent-speaker review of the 1,500-word baseline in 500-word bands, then extend the reviewed catalog toward the 2,500-rank goal.
4. Expand the reviewed phrase packs to 150, 500, and roughly 1,000 items alongside those word releases.
5. Test recognition wording with speakers of multiple Norwegian dialects.
6. Complete physical-device/accessibility QA, full-size performance measurements, TestFlight feedback, screenshots, and the prepared App Store Connect declarations.

## Reproduce and verify

```sh
git submodule update --init --recursive
Scripts/bootstrap_content_pipeline.sh
Scripts/run_content_pipeline.sh
Scripts/validate_content.py
```

Then run the shared `Norsk Word of the Day` scheme's tests in Xcode or with `xcodebuild test` on an installed iOS simulator.

## Verification record — 2026-07-17

- Strict content validator: passed for 1,500 words and 42 phrases, including regional-form structure, slang/proverb types, labels, tags, links, and duplicate checks.
- XCTest on an iPhone 17 Pro simulator: 20 of 20 tests passed against the bundled 1,500-word pack, including explicit slang/proverb linkage, regional-form validation/search, exact Bergen starter content, pack mapping, content-update recovery, cycle-boundary behavior, widget translation/midnight expiry, and a synthetic 2,500-word plus 1,000-phrase repository test.
- XCUITest on an iPhone 17 Pro Max simulator: 8 of 8 end-to-end UI journeys passed, including `koffer` search/detail, previous navigation, phrase construction, and in-app privacy, terms, and acknowledgement access.
- XCUITest on a 13-inch iPad Pro simulator: the critical learning-card, library-to-study, phrase-builder, and `koffer` regional search journeys passed after cross-device floating-tab accessibility coverage was added.
- Xcode Release static analysis: passed for the complete app and widget scheme after the 2026.07.3 content expansion.
- Release simulator build: succeeded for the complete 1,500-word app and widget with no compiler warnings or errors, using a single active simulator architecture and disabled index storage to fit the available temporary disk space.
- Unsigned generic iOS device archive: succeeded at `/tmp/DailyNorsk-Slang-Proverbs-20260717.xcarchive`; distribution signing and Organizer upload remain publisher-account actions.
- Debug app install, launch, and screenshot sanity checks succeeded on iPhone and 13-inch iPad simulators.
- Existing SwiftData progress migrated and loaded successfully after the scheduling fields were added.
- Pipeline determinism: two complete runs produced identical SHA-256 hashes for all four generated JSON reports.
- Submodules: clean and pinned to the revisions recorded in `CONTENT_SOURCES.md`, with their original GitHub fetch URLs intact.
- App icon: the 1024×1024 two-line `Daily` / `norsk` text icon uses a clean Avenir Next Demi Bold wordmark and compiles into the expected iPhone and iPad icon variants without asset-catalog warnings.
- Privacy manifests: present and valid in both built bundles, with no tracking/collection declaration and the App Group/UserDefaults required reason.
- Product-bundle audit: no submodules, source corpora, or generated candidate reports were copied into the app or widget.
- Release preflight: the 1,500-word content-size gate now passes; remaining publisher/editorial gates are example identifiers, unsigned content-rights/editorial record, support URL, and privacy-policy URL.
- Runtime-warning hardening: the placeholder or unavailable App Group now falls back to process-local defaults without constructing an invalid CFPreferences suite; Simulator speech practice exits with a physical-device message instead of opening its unreliable remote audio component; physical-device capture rejects empty audio storage before reaching Speech recognition. Recording fully removes its input tap, stops and resets its engine, and confirms shared-session deactivation. Speech synthesis uses its own system-managed audio session so a stopped record-only route cannot be reused for “Hear word” playback.
