import XCTest
@testable import Norsk_Word_of_the_Day

final class ContentRepositoryTests: XCTestCase {
    func testBundledContentLoadsAndMatchesManifest() throws {
        let repository = try ContentRepository(bundle: .main)

        XCTAssertEqual(repository.manifest.schemaVersion, 1)
        XCTAssertEqual(repository.words.count, 1_500)
        XCTAssertEqual(repository.phrases.count, 42)
        XCTAssertEqual(repository.manifest.packs.map(\.itemCount).reduce(0, +), 1_542)
        XCTAssertEqual(repository.packID(for: try XCTUnwrap(repository.words.first?.id)), "daily-norsk-words-1500")
        XCTAssertEqual(repository.packID(for: try XCTUnwrap(repository.phrases.first?.id)), "core-demo-phrases")
    }

    func testContentIDsAndWordRanksAreUnique() throws {
        let repository = try ContentRepository(bundle: .main)
        let allIDs = repository.words.map(\.id) + repository.phrases.map(\.id)

        XCTAssertEqual(Set(allIDs).count, allIDs.count)
        XCTAssertEqual(Set(repository.words.map(\.rank)).count, repository.words.count)
    }

    func testEveryPhraseHasResolvableFocusWords() throws {
        let repository = try ContentRepository(bundle: .main)

        for phrase in repository.phrases {
            XCTAssertFalse(phrase.focusWordIDs.isEmpty, phrase.norwegian)
            for wordID in phrase.focusWordIDs {
                XCTAssertNotNil(repository.word(withID: wordID), "Missing focus word for \(phrase.norwegian)")
            }
        }
    }

    func testRelatedPhrasesResolveBackFromReferencedWords() throws {
        let repository = try ContentRepository(bundle: .main)

        for phrase in repository.phrases {
            for wordID in Set(phrase.focusWordIDs + phrase.componentWordIDs) {
                XCTAssertTrue(
                    repository.relatedPhrases(for: wordID).contains(where: { $0.id == phrase.id }),
                    "Expected reverse relationship for \(phrase.norwegian)"
                )
            }
        }
    }

    func testWordRotationShowsEveryWordOncePerCycle() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var rotation = WordRotationStore(defaults: defaults)

        let cycle = (0..<repository.words.count).map { _ in
            rotation.nextWord(from: repository.words).id
        }

        XCTAssertEqual(Set(cycle).count, repository.words.count)
        XCTAssertEqual(Set(cycle), Set(repository.words.map(\.id)))
    }

    func testLearningRotationDoesNotRepeatAtWordCycleBoundary() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var rotation = LearningRotationStore(defaults: defaults)

        let cycle = (0..<repository.words.count).compactMap { _ -> UUID? in
            guard case let .word(word) = rotation.nextItem(from: repository, mode: .words) else { return nil }
            return word.id
        }
        guard case let .word(firstOfNextCycle) = rotation.nextItem(from: repository, mode: .words) else {
            return XCTFail("Expected a word")
        }

        XCTAssertEqual(Set(cycle), Set(repository.words.map(\.id)))
        XCTAssertNotEqual(cycle.last, firstOfNextCycle.id)
    }

    func testRotationRecoversWhenWordsAreRemoved() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var rotation = LearningRotationStore(defaults: defaults)

        _ = rotation.nextItem(from: repository, mode: .words)
        let remainingWords = Array(repository.words.dropLast(2))
        let reducedRepository = try ContentRepository(
            manifest: testManifest(wordCount: remainingWords.count),
            words: remainingWords,
            phrases: []
        )
        let cycle = (0..<remainingWords.count).map { _ in
            rotation.nextItem(from: reducedRepository, mode: .words).id
        }

        XCTAssertEqual(Set(cycle), Set(remainingWords.map(\.id)))
        XCTAssertEqual(cycle.count, Set(cycle).count)
    }

    func testMissingPhraseWordReferenceIsRejected() throws {
        let repository = try ContentRepository(bundle: .main)
        let source = try XCTUnwrap(repository.phrases.first)
        let missingID = UUID()
        let broken = PhraseEntry(
            id: source.id,
            teachingPriority: source.teachingPriority,
            contentVersion: source.contentVersion,
            level: source.level,
            norwegian: source.norwegian,
            english: source.english,
            literalTranslation: source.literalTranslation,
            usageNote: source.usageNote,
            type: source.type,
            register: source.register,
            componentWordIDs: [missingID],
            focusWordIDs: [missingID],
            exampleNorwegian: source.exampleNorwegian,
            exampleEnglish: source.exampleEnglish,
            alternateForms: source.alternateForms,
            regionalVariants: source.regionalVariants,
            slots: source.slots,
            isStandalone: source.isStandalone,
            isWidgetEligible: source.isWidgetEligible,
            tags: source.tags
        )

        XCTAssertThrowsError(
            try ContentRepository(
                manifest: repository.manifest,
                words: repository.words,
                phrases: [broken]
            )
        ) { error in
            XCTAssertEqual(
                error as? ContentRepositoryError,
                .invalidPhraseReference(phraseID: source.id, wordID: missingID)
            )
        }
    }

    func testDailySelectionIsStableAndIncludesPhrases() throws {
        let repository = try ContentRepository(bundle: .main)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let selector = DailyContentSelector(calendar: calendar)
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let items = (0..<20).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return selector.item(for: date, in: repository)
        }

        XCTAssertEqual(selector.item(for: start, in: repository), items[0])
        XCTAssertTrue(items.contains { $0.kind == .word })
        XCTAssertTrue(items.contains { $0.kind == .phrase })
    }

    func testMixedRotationUsesFourWordsThenOnePhrase() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var rotation = LearningRotationStore(defaults: defaults)

        let kinds = (0..<5).map { _ in
            rotation.nextItem(from: repository, mode: .mixed).kind
        }

        XCTAssertEqual(kinds, [.word, .word, .word, .word, .phrase])
    }

    func testPhraseRotationRespectsPrerequisitesAndCyclesWithoutRepeats() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var rotation = LearningRotationStore(defaults: defaults)
        let standaloneCount = repository.phrases.filter(\.isStandalone).count

        let initialPhrases = (0..<standaloneCount).compactMap { _ -> PhraseEntry? in
            guard case let .phrase(phrase) = rotation.nextItem(from: repository, mode: .phrases) else {
                return nil
            }
            return phrase
        }

        XCTAssertEqual(initialPhrases.count, standaloneCount)
        XCTAssertTrue(initialPhrases.allSatisfy(\.isStandalone))
        XCTAssertEqual(Set(initialPhrases.map(\.id)).count, standaloneCount)

        for _ in repository.words {
            _ = rotation.nextItem(from: repository, mode: .words)
        }

        let completeCycle = (0..<repository.phrases.count).compactMap { _ -> UUID? in
            guard case let .phrase(phrase) = rotation.nextItem(from: repository, mode: .phrases) else {
                return nil
            }
            return phrase.id
        }

        XCTAssertEqual(Set(completeCycle), Set(repository.phrases.map(\.id)))
    }

    func testProgressCanRecoverFromReviewToKnown() {
        let progress = LearningProgress(contentID: UUID(), contentKind: .phrase)

        progress.recordReview()
        progress.recordKnown()
        progress.recordKnown()
        XCTAssertEqual(progress.status, .learning)

        progress.recordKnown()
        progress.recordKnown()
        XCTAssertEqual(progress.status, .known)
        XCTAssertEqual(progress.contentKind, .phrase)
    }

    func testProgressSchedulingCreatesAndClearsDueReview() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let progress = LearningProgress(contentID: UUID(), contentKind: .word, now: start)

        progress.recordKnown(at: start)
        let nextReview = try XCTUnwrap(progress.nextReviewAt)
        XCTAssertGreaterThan(nextReview, start)
        XCTAssertFalse(progress.isDue(at: start))

        progress.recordReview(at: nextReview)
        XCTAssertEqual(progress.status, .review)
        XCTAssertEqual(progress.consecutiveKnown, 0)
        XCTAssertTrue(progress.isDue(at: nextReview))
    }

    func testSearchIndexCoversTranslationsInflectionsAndTags() throws {
        let repository = try ContentRepository(bundle: .main)
        let word = try XCTUnwrap(repository.words.first { !$0.inflections.isEmpty })
        let phrase = try XCTUnwrap(repository.phrases.first)

        XCTAssertTrue(LearningItem.word(word).searchText.localizedStandardContains(word.inflections[0]))
        XCTAssertTrue(LearningItem.word(word).searchText.localizedStandardContains(word.englishDefinition))
        XCTAssertTrue(LearningItem.phrase(phrase).searchText.localizedStandardContains(phrase.english))
        let regionalWord = try XCTUnwrap(repository.words.first { !($0.regionalVariants ?? []).isEmpty })
        let regionalForm = try XCTUnwrap(regionalWord.regionalVariants?.first?.form)
        XCTAssertTrue(LearningItem.word(regionalWord).searchText.localizedStandardContains(regionalForm))
        XCTAssertEqual(repository.items.count, repository.words.count + repository.phrases.count)
    }

    func testVestlandStarterContentIncludesBergenQuestionForms() throws {
        let repository = try ContentRepository(bundle: .main)
        let forms = Set(repository.words.map(\.displayForm))
        let phrases = Set(repository.phrases.map(\.norwegian))

        XCTAssertTrue(forms.isSuperset(of: ["ka", "koffer", "kor", "kordan", "eg", "ikkje"]))
        XCTAssertTrue(phrases.contains("Ka sier du?"))
        XCTAssertTrue(phrases.contains("Koffer det?"))

        let why = try XCTUnwrap(repository.words.first { $0.displayForm == "koffer" })
        XCTAssertEqual(why.lemma, "hvorfor")
        XCTAssertEqual(Set((why.regionalVariants ?? []).map(\.form)), ["koffor", "koffår"])
    }

    func testSlangAndTraditionalSayingsAreDeeplyLinked() throws {
        let repository = try ContentRepository(bundle: .main)
        let slang = repository.phrases.filter { $0.type == .slang }
        let proverbs = repository.phrases.filter { $0.type == .proverb }
        let phraseText = Set(repository.phrases.map(\.norwegian))

        XCTAssertGreaterThanOrEqual(slang.count, 6)
        XCTAssertGreaterThanOrEqual(proverbs.count, 10)
        XCTAssertTrue(phraseText.isSuperset(of: [
            "Ka skjer?",
            "Gå mann!",
            "Helt konge!",
            "Bedre sent enn aldri.",
            "Borte bra, men hjemme best.",
            "Morgenstund har gull i munn.",
        ]))
        XCTAssertTrue((slang + proverbs).allSatisfy { phrase in
            !phrase.focusWordIDs.isEmpty &&
            phrase.focusWordIDs.allSatisfy { repository.word(withID: $0) != nil } &&
            !(phrase.usageNote ?? "").isEmpty
        })

        let bergenExclamation = try XCTUnwrap(
            repository.phrases.first { $0.norwegian == "Gå mann!" }
        )
        XCTAssertTrue(bergenExclamation.tags.contains("bergensk"))
        XCTAssertEqual(bergenExclamation.register, .informal)
    }

    func testWidgetOverrideCarriesTranslationAndExpiresAtMidnight() throws {
        let repository = try ContentRepository(bundle: .main)
        let suiteName = "ContentRepositoryTests.\(UUID().uuidString)"
        let store = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { store.removePersistentDomain(forName: suiteName) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let start = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 10))
        )
        let phrase = try XCTUnwrap(repository.phrases.first)

        SharedDefaults.saveWidgetOverride(.phrase(phrase), at: start, calendar: calendar, store: store)

        let override = try XCTUnwrap(SharedDefaults.widgetItem(at: start, store: store))
        XCTAssertEqual(override.id, phrase.id)
        XCTAssertEqual(override.english, phrase.english)

        let midnight = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start)))
        XCTAssertNil(SharedDefaults.widgetItem(at: midnight, store: store))
    }

    func testRepositoryRejectsEmptyWordsInvalidLanguageAndInvalidRank() throws {
        XCTAssertThrowsError(
            try ContentRepository(
                manifest: testManifest(wordCount: 0),
                words: [],
                phrases: []
            )
        ) { error in
            XCTAssertEqual(error as? ContentRepositoryError, .emptyWordCollection)
        }

        let word = makeWord(index: 1)
        XCTAssertThrowsError(
            try ContentRepository(
                manifest: testManifest(wordCount: 1, language: "nn-NO"),
                words: [word],
                phrases: []
            )
        ) { error in
            XCTAssertEqual(error as? ContentRepositoryError, .invalidLanguage("nn-NO"))
        }

        let invalidRankWord = WordEntry(
            id: word.id,
            rank: 0,
            teachingPriority: word.teachingPriority,
            frequencyBand: word.frequencyBand,
            contentVersion: word.contentVersion,
            level: word.level,
            lemma: word.lemma,
            displayForm: word.displayForm,
            partOfSpeech: word.partOfSpeech,
            englishDefinition: word.englishDefinition,
            norwegianDefinition: word.norwegianDefinition,
            gender: word.gender,
            inflections: word.inflections,
            exampleNorwegian: word.exampleNorwegian,
            exampleEnglish: word.exampleEnglish,
            alternateMeanings: word.alternateMeanings,
            regionalVariants: word.regionalVariants,
            tags: word.tags
        )
        XCTAssertThrowsError(
            try ContentRepository(
                manifest: testManifest(wordCount: 1),
                words: [invalidRankWord],
                phrases: []
            )
        ) { error in
            XCTAssertEqual(
                error as? ContentRepositoryError,
                .invalidWordRank(wordID: invalidRankWord.id, rank: 0)
            )
        }
    }

    func testProductionScaleRepositoryRemainsResponsive() throws {
        let words = (1...2_500).map(makeWord)
        let phrases = (1...1_000).map { index in
            let word = words[(index - 1) % words.count]
            return PhraseEntry(
                id: UUID(),
                teachingPriority: index,
                contentVersion: 1,
                level: .a1,
                norwegian: "Eksempel \(index)",
                english: "Example \(index)",
                literalTranslation: nil,
                usageNote: nil,
                type: .collocation,
                register: .neutral,
                componentWordIDs: [word.id],
                focusWordIDs: [word.id],
                exampleNorwegian: "Dette er eksempel \(index).",
                exampleEnglish: "This is example \(index).",
                alternateForms: [],
                regionalVariants: nil,
                slots: [],
                isStandalone: true,
                isWidgetEligible: index <= 100,
                tags: ["scale-test"]
            )
        }
        let start = Date()
        let repository = try ContentRepository(
            manifest: testManifest(wordCount: words.count, phraseCount: phrases.count),
            words: words,
            phrases: phrases
        )
        let firstWord = try XCTUnwrap(repository.word(withID: words.first?.id ?? UUID()))
        let related = repository.relatedPhrases(for: firstWord.id)
        let matches = repository.items.filter { $0.searchText.localizedStandardContains("Example 999") }
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(repository.items.count, 3_500)
        XCTAssertEqual(repository.packID(for: firstWord.id), "test-words")
        XCTAssertEqual(repository.packID(for: phrases[0].id), "test-phrases")
        XCTAssertFalse(related.isEmpty)
        XCTAssertFalse(matches.isEmpty)
        XCTAssertLessThan(elapsed, 5)
    }

    func testInvalidRegionalVariantsAreRejected() throws {
        let emptyVariantWord = makeWord(
            index: 1,
            regionalVariants: [RegionalVariant(form: "", region: "Bergen", note: nil)]
        )
        XCTAssertThrowsError(
            try ContentRepository(
                manifest: testManifest(wordCount: 1),
                words: [emptyVariantWord],
                phrases: []
            )
        ) { error in
            XCTAssertEqual(
                error as? ContentRepositoryError,
                .invalidRegionalVariant(itemID: emptyVariantWord.id)
            )
        }

        let duplicateVariantWord = makeWord(
            index: 1,
            regionalVariants: [
                RegionalVariant(form: "Koffer", region: "Bergen", note: nil),
                RegionalVariant(form: "koffer", region: "Vestland", note: nil),
            ]
        )
        XCTAssertThrowsError(
            try ContentRepository(
                manifest: testManifest(wordCount: 1),
                words: [duplicateVariantWord],
                phrases: []
            )
        ) { error in
            XCTAssertEqual(
                error as? ContentRepositoryError,
                .duplicateRegionalVariant(itemID: duplicateVariantWord.id, form: "koffer")
            )
        }
    }

    private func testManifest(
        wordCount: Int,
        phraseCount: Int = 0,
        language: String = "nb-NO"
    ) -> ContentManifest {
        var packs = [
            ContentPack(
                id: "test-words",
                kind: .word,
                version: 1,
                resource: "words.json",
                itemCount: wordCount,
                minimumFrequencyRank: wordCount > 0 ? 1 : nil,
                maximumFrequencyRank: wordCount > 0 ? wordCount : nil
            ),
        ]
        if phraseCount > 0 {
            packs.append(
                ContentPack(
                    id: "test-phrases",
                    kind: .phrase,
                    version: 1,
                    resource: "phrases.json",
                    itemCount: phraseCount,
                    minimumFrequencyRank: nil,
                    maximumFrequencyRank: nil
                )
            )
        }
        return ContentManifest(
            schemaVersion: ContentRepository.supportedSchemaVersion,
            contentVersion: "test",
            language: language,
            packs: packs
        )
    }

    private func makeWord(index: Int) -> WordEntry {
        makeWord(index: index, regionalVariants: nil)
    }

    private func makeWord(index: Int, regionalVariants: [RegionalVariant]?) -> WordEntry {
        WordEntry(
            id: UUID(),
            rank: index,
            teachingPriority: index,
            frequencyBand: index <= 500 ? .core500 : .rank501To1000,
            contentVersion: 1,
            level: .a1,
            lemma: "ord\(index)",
            displayForm: "ord \(index)",
            partOfSpeech: .noun,
            englishDefinition: "word \(index)",
            norwegianDefinition: "et eksempelord",
            gender: .neuter,
            inflections: ["ordet \(index)"],
            exampleNorwegian: "Dette er ord \(index).",
            exampleEnglish: "This is word \(index).",
            alternateMeanings: [],
            regionalVariants: regionalVariants,
            tags: ["scale-test"]
        )
    }
}
