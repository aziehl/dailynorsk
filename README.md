# Daily Norsk

A native SwiftUI Norwegian word-and-phrase learning app with a Vestland focus and a WidgetKit extension.

## Open the project

```sh
open NorskWordOfTheDay.xcodeproj
```

The current implementation includes a four-tab Learn/Library/Review/Progress interface, versioned word and phrase packs, mixed prerequisite-aware cards, searchable translations, inflections, and regional forms, Norwegian speech playback and recognition practice, SwiftData review scheduling, deterministic daily widget content, interactive widget advancement, exact word/phrase deep links, automated validation, and repository tests. The bundled offline catalog contains 1,500 words and 42 phrases. Its first 32 lessons are hand-curated Vestland/Bergen, slang, and proverb-linked vocabulary; the expanded frequency lexicon is built from attributed open lexical evidence and should continue through fluent-speaker editorial review.

Daily Norsk teaches standard written forms while foregrounding clearly labeled Vestland and Bergen speech. Dialect spellings are treated as variable representations of speech, not as a replacement written standard. Slang lessons identify informal or regional register; proverb lessons explain literal meaning, current context, and words that mainly survive inside a fixed saying.

Before running on a physical device, complete Milestone 0 in `BUILD_PLAN.md` and replace all example signing identifiers.

## Project layout

```text
NorskWordOfTheDay/
  App/                 SwiftUI app, progress, and speech services
  Shared/              Models and state used by both targets
  Resources/           Versioned bundled word and phrase JSON
  SupportingFiles/     App plist and entitlements
NorskWidget/
  SupportingFiles/     Widget plist and entitlements
NorskWordOfTheDay.xcodeproj/
NorskWordOfTheDayTests/
NorskWordOfTheDayUITests/
ContentPipeline/        Review inputs and versioned editorial overrides
References/             Pinned, updateable Git submodules
Scripts/                Validation and candidate-generation commands
BUILD_PLAN.md
IMPLEMENTATION_STATUS.md
```

The expanded roadmap now has a functional 1,500-word offline baseline and continues toward deeper fluent-speaker review, useful lexical vocabulary through approximately raw frequency rank 2,500, and about 1,000 cross-linked phrases. See `IMPLEMENTATION_STATUS.md` for the exact boundary between completed engineering and human editorial/release work.

## Content tooling

The project includes pinned Git submodules for frequency and linguistic evidence plus checksum-pinned fetchers for the licensed Wiktionary extraction and Tatoeba sentence-pair export. Run `git submodule update --init --recursive`, then follow `ContentPipeline/README.md`. Generated candidate and provenance reports remain separate from the app binary.

Run `Scripts/release_preflight.sh` before every submission attempt. It validates the bundled catalog and reports unresolved publisher-owned identifiers, signing, editorial sign-off, content-size, and hosted-URL gates. Support and privacy URLs are supplied through `DAILY_NORSK_SUPPORT_URL` and `DAILY_NORSK_PRIVACY_URL` so private release configuration does not need to be committed.

## Publication and legal

Before submission, work through `Release/APP_STORE_SUBMISSION.md`, publish `LEGAL/PRIVACY_POLICY.md` at the App Store privacy URL, retain `THIRD_PARTY_NOTICES.md`, and complete the content-rights sign-off in `LEGAL/CONTENT_RIGHTS.md`. Apple’s standard EULA is intentionally used; that decision is recorded in `LEGAL/TERMS_AND_LICENSE.md`.

## App data

- Bundled definitions, translations, examples, and grammar live in validated, versioned JSON packs and work offline. Wiktionary-derived lexical fields are attributed in-app under CC BY-SA 4.0, and Tatoeba example pairs under CC BY 2.0 France.
- Learning history, known/review answers, review dates, view counts, and pronunciation attempts are stored locally with SwiftData.
- App Group defaults contain only lightweight app/widget selection state; temporary widget advances expire at the next local midnight.
- The app includes a compiled 1024×1024 icon asset and Xcode-generated device variants.

## Verification

```sh
Scripts/validate_content.py
Scripts/release_preflight.sh
xcodebuild test -project NorskWordOfTheDay.xcodeproj \
  -scheme "Norsk Word of the Day" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:NorskWordOfTheDayTests \
  -only-testing:NorskWordOfTheDayUITests
```
