# App Store submission packet

Last audited: 17 July 2026

## Proposed product metadata

- Name: `Daily Norsk`
- Subtitle: `Vestland words & phrases`
- Primary category: Education
- Secondary category: Reference (optional)
- Version: `1.0`
- Build: increment from `1` for every uploaded archive
- Promotional text: `Build useful Norwegian with clearly labeled Vestland and Bergen speech, a daily widget, focused review, and optional speech practice.`
- Keywords: `norwegian,norsk,vestland,bergen,bergensk,bokmål,phrases,widget,language,learn`

Do not claim that 2,500 lessons are included until reviewed content at that scale is actually bundled. The current offline catalog contains 1,500 words and 42 phrases; distinguish the hand-curated Vestland layer from the attributed frequency expansion and do not imply that all 1,500 entries received native-speaker editorial approval until that review is recorded.

## Required publisher-owned fields

These cannot be safely invented in source code:

- [ ] Apple Developer Program membership is active and all updated agreements are accepted.
- [ ] Legal seller/publisher name is confirmed.
- [ ] Unique app bundle ID is registered; replace `com.example.NorskWordOfTheDay`.
- [ ] Widget bundle ID is registered under the app ID; replace `com.example.NorskWordOfTheDay.Widget`.
- [ ] App Group is registered for both targets; replace `group.com.example.NorskWordOfTheDay` in both entitlements and `SharedDefaults.swift`.
- [ ] Development team and distribution signing are configured for both targets.
- [ ] Stable HTTPS Support URL with current contact information is live.
- [ ] `LEGAL/PRIVACY_POLICY.md` is published at a stable HTTPS Privacy Policy URL.
- [ ] Privacy and Support URLs are tested without authentication, redirects to broken pages, or TLS errors.
- [ ] Copyright field names the actual rights holder, for example `2026 Publisher Legal Name`.
- [ ] Paid-app agreements, tax, and banking are completed if the app will be paid or use in-app purchases.

Run `Scripts/release_preflight.sh` before archiving. The check intentionally fails while any repository-detectable publication gate remains. Supply `DAILY_NORSK_SUPPORT_URL` and `DAILY_NORSK_PRIVACY_URL` as HTTPS values when those pages are live; the script does not store publisher URLs or credentials.

## App Privacy answers

For the audited build:

- Tracking: No.
- Data used for tracking: None.
- Third-party analytics/advertising SDKs: None.
- Publisher data collection: Data Not Collected.
- Accounts: None.
- Privacy choices URL: optional; the privacy policy explains local reset and permission revocation.

Reasoning: all learning state remains in the app/App Group container. Optional speech audio may be processed by Apple solely for the immediate recognition request; the publisher does not receive or retain it. Apple states that developers are not responsible for disclosing data collected by Apple, and transient data used only to service a request does not meet Apple’s definition of collection. The publisher must review and certify these answers in App Store Connect and revisit them if any backend, analytics, crash-reporting SDK, sync, support form, or new data flow is added.

The app and widget each include `PrivacyInfo.xcprivacy`, declaring no tracking or collected data and the `CA92.1` reason for app/App Group `UserDefaults` access.

## Permissions and review notes

- Microphone and speech-recognition prompts are delayed until the user taps `Check recognition`.
- The screen visibly indicates the listening state and explains that audio is not saved.
- On-device Norwegian recognition is required when supported; otherwise Apple may process audio for the immediate request.
- The feature is optional and the app remains useful when permission is denied.

Suggested App Review note:

> The app requires no login. Optional speech practice is reached from a revealed word or phrase by tapping Check recognition. The app requests microphone and speech-recognition permission only at that point. Audio is not saved, and all learning history is stored locally. Add the widget from the system widget gallery to test translated daily content and its Next item control.

## Export compliance

The app contains no custom cryptography and no third-party networking or cryptographic library. `ITSAppUsesNonExemptEncryption` is set to `false` in the app and widget property lists. Re-evaluate this answer if networking, authentication, encrypted storage, or third-party SDKs are added.

## Content rights and licenses

- Use Apple’s standard EULA; do not enter a custom EULA for version 1.0.
- Confirm the project owner has rights to all project-authored content and the generated icon.
- Complete the sign-off in `LEGAL/CONTENT_RIGHTS.md` for the release content pack.
- Do not include candidate reports or source corpora in either target.
- Preserve both reference repositories as Git submodules and retain upstream license files.
- Preserve the English Wiktionary/Kaikki attribution, modification notice, source links, and CC BY-SA 4.0 terms, plus Tatoeba attribution, sentence provenance, modification notice, and CC BY 2.0 France terms, in the app and repository.

## Age rating and audience

- Complete Apple’s current age-rating questionnaire in App Store Connect.
- Complete the questionnaire from the actual shipping catalog. The app has no visual depictions, gambling, contests, unrestricted web browsing, social features, messaging, or user-generated content; review lexical definitions and examples for any language-content disclosures required by the current questionnaire.
- Do not mark the app Made for Kids unless the publisher intentionally targets children and completes the additional Kids Category design, analytics, advertising, parental-gate, and privacy review.

The final rating is assigned by Apple and may vary by region; do not hard-code a rating claim in marketing material before completing the questionnaire.

## Accessibility declaration

The app uses SwiftUI semantic controls, Dynamic Type styles, text alternatives through labels, system color schemes, non-color status labels, and Reduce Motion handling. Before publishing Accessibility Nutrition Labels, complete common-task testing on both iPhone and iPad with:

- [ ] VoiceOver
- [ ] Voice Control
- [ ] text at 200% or the required accessibility sizes
- [ ] Dark Mode
- [ ] Differentiate Without Color
- [ ] Increase Contrast
- [ ] Reduce Motion

Only claim features for which every common task passes. Inaccurate claims can be treated as misleading metadata.

## Build and media

- [x] Xcode 26.6 with iOS 26.5 SDK is installed, satisfying Apple’s iOS 26 SDK upload minimum in effect from 28 April 2026.
- [ ] Archive a generic iOS Device Release build with distribution signing.
- [ ] Run Organizer validation and resolve every error or warning.
- [ ] Upload to App Store Connect and complete TestFlight internal testing.
- [ ] Test the app and widget on at least one physical iPhone and one physical iPad running current iOS/iPadOS.
- [ ] Test migration, launch, permissions denied/granted, airplane mode, day rollover, widget refresh, VoiceOver, large text, and low-storage behavior.
- [ ] Upload at least one accurate screenshot for each required supported device class; one to ten screenshots are allowed per device size.
- [ ] Ensure screenshots show the shipping reviewed content and contain no simulator/debug artifacts.
- [ ] Select the uploaded build, complete version description, What’s New, review contact, and release method.
- [ ] Submit through the App Review draft submission flow.

## Commercial-content gate

The catalog is now large enough to avoid short-cycle repetition, but commercial release still requires fluent-speaker sampling and sign-off across the generated bands. Retain the in-app Wiktionary/Kaikki and Tatoeba attribution and license terms in every distributed build.

## Repository verification — 17 July 2026

- [x] 20 unit tests pass after the 2026.07.3 content release; coverage includes regional forms, slang/proverb linkage, strict validation, rotation recovery, pack mapping, scheduling, widget state, and a 2,500-word/1,000-phrase repository-scale test.
- [x] All 8 UI journeys pass on iPhone; critical learning, library, phrase-builder, and regional-search journeys also pass on 13-inch iPad.
- [x] Release simulator build and Xcode static analysis pass with no warnings.
- [x] Unsigned generic-device archive succeeds and contains both privacy manifests, app/widget content, and no candidate reports, corpora, or reference repositories.
- [x] Current phone and tablet layouts received a simulator screenshot sanity check.
- [ ] `Scripts/release_preflight.sh` passes. It currently identifies publisher/editorial/content gates listed above.
