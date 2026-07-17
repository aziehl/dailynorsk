# Daily Norsk — Build Plan

This file turns the product idea into small, finishable milestones. Work from top to bottom and complete the **Definition of done** before moving to the next milestone.

The long-term content goal is broader than a 500-word app: build a reliable core first, extend coverage through approximately the 2,500 most frequent useful lexical lemmas, and teach high-value phrases that combine those words naturally.

## Content scope and releases

Frequency rank and teaching order are different fields. Preserve corpus rank as evidence, but sequence learning by usefulness, level, grammatical prerequisites, and phrase coverage.

| Release | Word coverage | Phrase coverage | Purpose |
|---|---:|---:|---|
| Prototype | 50 reviewed words | 20 reviewed phrases | Prove models, cards, audio, and validation |
| Core release | 500 useful lemmas | 150 common phrases | Everyday beginner foundation |
| Expansion A | Through roughly rank 1,500 | 500 total phrases | Broader A1–B1 lexical coverage |
| Expansion B | Useful lexical words from roughly ranks 1,501–2,500 | 1,000 total phrases | Greater reading and conversation coverage |

The exact number of word entries will be lower than 2,500 raw tokens because inflections, proper names, duplicate lemmas, abbreviations, and unsuitable corpus artifacts are removed. Do not fill a quota with poor learning items.

## Product decisions

- Target iOS 17 or later.
- Use SwiftUI, WidgetKit, App Intents, AVSpeechSynthesizer, and local JSON.
- Work offline; do not add a backend for version 1.
- Treat the daily word, manually requested extra words, and review words as separate concepts.
- Store words and phrases as distinct content types with shared scheduling and progress concepts.
- Link every phrase to its component words and one or more focus words.
- Preserve both corpus frequency rank and editorial teaching priority.
- Package content into independently versioned bands so later vocabulary can ship without replacing learner progress.
- Describe pronunciation feedback as speech recognition, not an accuracy score.
- Use Bokmål (`nb-NO`) for standard written forms while clearly labeling Vestland and Bergen representations of speech.
- Ship only content whose source and redistribution rights are documented.

## Milestone 0 — Open and configure the scaffold

- [ ] Open `NorskWordOfTheDay.xcodeproj` in Xcode.
- [ ] Choose your Apple development team for both targets.
- [ ] Replace `com.example.NorskWordOfTheDay` with your bundle identifier.
- [ ] Replace `group.com.example.NorskWordOfTheDay` in both entitlement files and in `SharedDefaults.swift` with an App Group you own.
- [ ] Enable the App Groups capability for both targets in Signing & Capabilities.
- [ ] Run the app in an iPhone simulator.
- [ ] Add the widget to the simulator Home Screen.

**Definition of done:** the app shows a sample card, speaks Norwegian, advances to a new word, and the widget renders without an error.

## Milestone 1 — Stabilize the content models and sample dataset

- [ ] Review the fields in `Shared/WordEntry.swift` against noun, verb, adjective, and function-word needs.
- [ ] Add `frequencyRank`, `teachingPriority`, `frequencyBand`, `contentVersion`, and CEFR/difficulty fields without treating any one source as absolute truth.
- [ ] Add a separate `PhraseEntry` model with phrase text, natural English translation, optional literal translation, usage note, register, phrase type, component word IDs, focus word IDs, examples, and tags.
- [ ] Define phrase types such as collocation, fixed expression, conversational frame, particle verb, idiom, and sentence stem.
- [ ] Decide conventions for articles, verb infinitive markers, gender, alternative forms, inflections, separable components, punctuation, and capitalization.
- [ ] Define stable IDs that do not change when ranks, translations, or editorial fields are corrected.
- [ ] Define a versioned content manifest for word packs and phrase packs.
- [ ] Add JSON validation errors that identify the broken entry and field.
- [ ] Expand the scaffold data to 50 reviewed sample words and 20 reviewed phrases.
- [ ] Add unit tests for decoding every entry, unique IDs, valid word references, rank rules, and content-pack versions.
- [ ] Add a dataset attribution/source document.

**Definition of done:** 50 words and 20 phrases decode, cross-link, display, and speak correctly, with automated validation and source notes.

## Milestone 2 — Finish word and phrase flash cards

- [ ] Split `ContentView` into card front, card back, and controls.
- [ ] Add a phrase card that shows the complete phrase first, then translation, usage note, component words, and a natural context sentence or mini-dialogue.
- [ ] Let a learner move from a word card to related phrases and from a phrase back to its component words.
- [ ] Add a card flip animation with Reduce Motion support.
- [ ] Speak a word, phrase, complete example sentence, or dialogue line independently.
- [ ] Add “I knew this” and “Review again” actions.
- [x] Add previous/next behavior without losing progress.
- [ ] Clearly label literal translations as notes rather than presenting unnatural English as the definition.
- [ ] Display register and usage warnings for formal, informal, dated, sensitive, or regionally marked phrases.
- [x] Add loading and dataset-error screens.
- [ ] Check Dynamic Type, VoiceOver labels, contrast, and landscape layouts.

**Definition of done:** a learner can reveal, hear, grade, cross-link, and advance through both word and phrase cards using touch or VoiceOver.

## Milestone 3 — Make rotation deterministic and testable

- [ ] Move rotation state from ad-hoc defaults into a versioned state structure.
- [ ] Create a shuffled queue at the beginning of each cycle.
- [ ] Guarantee every word appears once before a new cycle begins.
- [x] Prevent the last word of one cycle from immediately repeating as the first of the next.
- [ ] Define the local-calendar rule for the daily word.
- [ ] Keep manual “extra word” advances separate from the scheduled daily word.
- [ ] Maintain separate unseen queues for words and phrases, with a configurable mix such as four words followed by one phrase.
- [ ] Do not schedule a phrase before enough of its focus words have been introduced unless it is explicitly marked standalone.
- [ ] Keep daily-word, daily-phrase, extra-item, and review selection rules distinct.
- [ ] Add tests for cycle boundaries, deleted words, new dataset versions, and time-zone changes.

**Definition of done:** automated tests prove that complete word and phrase cycles have no duplicates or omissions, respect prerequisites, and survive relaunches.

## Milestone 4 — Persist learning progress for every content type

- [ ] Add a SwiftData progress model keyed by stable content ID and content type, or separate `WordProgress` and `PhraseProgress` models with the same scheduling interface.
- [ ] Store first/last seen dates, view count, known/review counts, and pronunciation attempts.
- [ ] Define statuses: new, seen, learning, known, and review.
- [ ] Track phrase comprehension separately from knowledge of its component words.
- [x] Add summaries by content type, frequency band, CEFR level, and content pack.
- [ ] Add a reset-progress confirmation flow.
- [ ] Define a migration policy before changing the production model.

**Definition of done:** word and phrase progress survive relaunches and content-pack updates, and can be reset safely without damaging bundled content.

## Milestone 5 — Complete widget behavior

- [ ] Provide polished small and medium layouts.
- [ ] Prepare timeline entries for the next 7–14 local midnights.
- [ ] Make the widget card deep-link to the exact word in the app.
- [ ] Make the interactive next button update shared state and reload the timeline.
- [ ] Decide whether the widget alternates words and short phrases or offers separate widget configurations.
- [ ] Keep long phrases out of small widgets using an explicit widget-eligibility field rather than truncating away meaning.
- [ ] Store only widget-critical state in App Group defaults.
- [ ] Test fresh installs, locked devices, midnight changes, and app/widget state disagreement.

**Definition of done:** the widget changes daily, manual advance works within WidgetKit limits, and every displayed word opens the matching app card.

## Milestone 6 — Add honest pronunciation feedback

- [ ] Add microphone and speech-recognition usage descriptions.
- [ ] Request permissions only when the learner starts recording.
- [ ] Capture speech using Apple’s Speech framework with a Norwegian locale.
- [ ] Prefer a short phrase or example sentence over a single isolated word when recognition is unreliable.
- [ ] Grade recognition against the spoken target while accepting documented alternative forms and harmless punctuation differences.
- [ ] Normalize capitalization and punctuation before comparing results.
- [ ] Report “Heard correctly,” “We heard…,” or “Try again”; do not report a fake precision percentage.
- [ ] Handle denial, unavailable recognition, silence, and offline limitations.
- [ ] Test multiple Norwegian dialects before choosing user-facing wording.

**Definition of done:** users understand that the feature checks recognition, permissions are handled gracefully, and valid dialect variation is not presented as objectively wrong.

## Milestone 7 — Build the reproducible lexical-content pipeline

- [ ] Collect licensed frequency evidence from more than one suitable Bokmål corpus or frequency source.
- [ ] Keep source rank, normalized frequency, corpus name, date/version, and license in editorial metadata.
- [ ] Start with at least the top 5,000 raw tokens so filtering still leaves good candidates through rank 2,500.
- [ ] Normalize casing and Unicode without destroying meaningful spelling distinctions.
- [ ] Lemmatize inflected forms so `er`, `var`, and `vært` can map to the teaching entry `å være` where appropriate.
- [ ] Preserve useful irregular forms as searchable inflections rather than separate ranked words.
- [ ] Identify and review homographs that need separate senses or parts of speech.
- [ ] Flag proper names, numbers, URLs, abbreviations, profanity, malformed tokens, corpus artifacts, and foreign-language leakage.
- [ ] Distinguish lexical words from grammatical/function words, but retain essential function words in the core pack.
- [ ] Combine multiple corpus signals without inventing a falsely precise universal rank.
- [ ] Produce reports for duplicates, excluded tokens, missing ranks, conflicting lemmas, and changes between pipeline versions.
- [ ] Make pipeline output deterministic and keep editorial overrides in version control.
- [x] Carry versioned Vestland/Bergen form suggestions into candidate reports and flag every one for local fluent-speaker review.

**Definition of done:** the same source inputs and editorial override file reproduce the same ranked candidate list and an auditable exclusion report.

## Milestone 8 — Produce the reviewed core 500-word pack

- [ ] Select 500 useful learner lemmas from the highest-frequency candidate pool.
- [ ] Include essential function words even when they require phrase-first teaching.
- [ ] Write original concise English definitions and natural Bokmål example sentences.
- [ ] Review gender, articles, inflections, translations, level tags, sense splits, and Bokmål consistency.
- [ ] Ensure every entry has at least one useful example and at least one phrase candidate.
- [ ] Have a fluent Norwegian speaker review every entry.
- [ ] Record the source and license for every imported data field.
- [ ] Run the automated validator and duplicate/overlap reports.

**Definition of done:** all 500 core entries are linguistically reviewed, machine validated, pedagogically useful, cross-linkable to phrases, and cleared for distribution.

## Milestone 9 — Expand lexical coverage through rank 2,500

- [ ] Divide candidates into review bands: 501–1,000, 1,001–1,500, 1,501–2,000, and 2,001–2,500.
- [ ] Within each band, prioritize useful nouns, verbs, adjectives, and adverbs over corpus noise or opaque items with little independent teaching value.
- [ ] Keep source frequency rank visible in editorial data while assigning a separate teaching priority and estimated CEFR level.
- [ ] Decide whether related senses share one entry or require separate cards; document the rule and apply it consistently.
- [ ] Add common derivational families and cross-links without pretending that knowing one form means knowing all related words.
- [ ] Add domain tags such as home, work, school, travel, health, news, feelings, nature, and public services.
- [ ] Balance written-corpus frequency with conversational usefulness, marking the evidence used for each decision.
- [ ] Give every accepted lexical entry original definitions, inflections, a natural example, pronunciation text, and at least one phrase relationship.
- [ ] Review and ship one 500-rank band at a time rather than editing all 2,000 expansion candidates simultaneously.
- [ ] Run regression validation against existing IDs and learner progress before each pack release.
- [ ] Measure coverage and learner feedback after each band before finalizing the next one.

**Definition of done:** each expansion band is independently versioned, reviewed, licensed, validated, and installable without changing stable IDs or losing progress from earlier packs.

## Milestone 10 — Build the phrase corpus

- [ ] Define the first phrase inventory from high-value collocations, conversational frames, fixed expressions, particle verbs, idioms, and sentence stems.
- [ ] Mine phrase candidates from licensed corpus evidence and learner needs; never assume that two frequent adjacent words form a useful phrase.
- [ ] Start with 150 phrases for the core 500 words, expand to 500 phrases by the rank-1,500 release, and target about 1,000 by the rank-2,500 release.
- [ ] Favor reusable patterns such as `har lyst til å …` and `kan du …?`, storing variable slots explicitly where useful.
- [ ] Store a natural English equivalent, optional literal translation, usage explanation, register, level, phrase type, and component/focus word IDs.
- [ ] Add one natural context sentence or two-line mini-dialogue for each phrase.
- [ ] Record acceptable variants, word-order constraints, required prepositions, reflexive pronouns, and inflection behavior.
- [ ] Avoid fragmenting trivial combinations into separate cards; require a phrase to add meaning, grammar, fluency, or strong collocational value.
- [ ] Flag expressions whose translation is context dependent, culturally specific, sensitive, regional, formal, informal, or dated.
- [ ] Have a fluent speaker review naturalness, translation, context, register, and whether the phrase is genuinely useful.
- [ ] Validate that all component and focus word IDs exist and that prerequisite sequencing is possible.
- [ ] Generate coverage reports showing phrases per word, words with no phrases, overrepresented topics, and duplicate phrase variants.

**Definition of done:** the phrase pack meets its release-size target, every phrase is natural and cross-linked, and automated reports expose gaps and duplicates.

## Milestone 11 — Add learning paths, discovery, and phrase practice

- [x] Add filters for core words, expansion bands, phrases, level, topic, part of speech, content pack, and learning status.
- [x] Add search across lemmas, display forms, inflections, English meanings, phrase text, and tags.
- [ ] Create mixed sessions that introduce a word and later reinforce it through one or more phrases.
- [ ] Add cloze practice for phrases only after the reveal/recognition flow is stable.
- [x] Add a phrase-builder exercise that orders components and lets learners select documented alternate forms.
- [ ] Show coverage such as “420 core words learned” and “85 phrases learned” without conflating the two.
- [ ] Keep review scheduling based on learner evidence rather than raw frequency rank.

**Definition of done:** learners can deliberately study a frequency band or phrase set, find known content, and practice words in meaningful combinations.

## Milestone 12 — Polish and release

- [ ] Add widget previews, final launch appearance, and remaining empty/error states. (App icon complete.)
- [ ] Add analytics only if there is a specific product question and document privacy impact.
- [x] Add UI tests for reveal, deep-link selection, library-to-study navigation, and progress surfaces.
- [x] Add in-app privacy, terms, and acknowledgement access plus UI coverage.
- [x] Add app/widget privacy manifests, export metadata, licensing ledgers, content-rights record, and App Store Connect answer sheet.
- [ ] Add further UI tests for widget interaction, word/phrase cross-links, pack filters, and long mixed sessions.
- [ ] Test on small and large phones and the oldest supported iOS version.
- [ ] Profile launch, widget load, memory, and speech behavior.
- [ ] Verify that loading roughly 2,500 lexical entries plus 1,000 phrases does not harm launch or widget performance.
- [ ] Publish the prepared privacy policy and support page, capture final screenshots, and enter the prepared metadata in App Store Connect.
- [ ] Run TestFlight with Norwegian learners and address the highest-impact feedback.

**Definition of done:** the release build passes tests and accessibility checks, content rights are documented by pack, and external learners have completed word, phrase, and mixed-session flows in TestFlight.

## Later, only after version 1

- Spaced repetition beyond “know/review.”
- iCloud/CloudKit sync.
- Remote content-pack updates after local versioning and migrations are proven.
- Additional Norwegian written standards or dialect-oriented audio.
- Acoustic or phoneme-level pronunciation assessment, only with a validated dialect-aware approach.
- Accounts, subscriptions, or a backend.

## Next working session

1. Complete the developer-owned signing and App Group settings in Milestone 0.
2. Have a fluent Norwegian editor review and correct the demo content.
3. Promote the first 50 reviewed word candidates while preserving their stable IDs and source evidence.
4. Add the reviewed items as a separately versioned content pack and run the validator and tests.
5. Continue in 500-rank editorial bands; do not automatically ship generated candidates.

The exact implementation boundary and verification record live in `IMPLEMENTATION_STATUS.md`.
