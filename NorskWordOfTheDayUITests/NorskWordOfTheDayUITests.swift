import AppIntents
import XCTest

final class NorskWordOfTheDayUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testWordCardRevealsTranslation() {
        launch(deepLink: "norskword://word/8F18F091-321C-4EF2-A094-BAA95ED0E663")
        XCTAssertTrue(app.staticTexts["learningItemTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["learningItemTitle"].label, "å forstå")

        let reveal = app.buttons["revealButton"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 3))
        reveal.tap()

        let translation = app.staticTexts["translationText"]
        XCTAssertTrue(translation.waitForExistence(timeout: 3))
        XCTAssertEqual(translation.label, "to understand")
    }

    func testSimulatorSpeechPracticeAvoidsUnavailableAudioServer() {
        launch(deepLink: "norskword://word/8F18F091-321C-4EF2-A094-BAA95ED0E663")
        let hearButton = app.buttons["hearItemButton"]
        XCTAssertTrue(hearButton.waitForExistence(timeout: 3))
        hearButton.tap()

        app.buttons["revealButton"].tap()

        let speechButton = app.buttons["speechRecognitionButton"]
        for _ in 0..<7 where !speechButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(speechButton.waitForExistence(timeout: 3))
        speechButton.tap()

        let status = app.staticTexts["speechRecognitionStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 3))
        XCTAssertEqual(status.label, "Speech recognition requires a physical iPhone or iPad.")
    }

    func testPhraseDeepLinkLaunchesExactCard() {
        launch(deepLink: "norskword://phrase/4AABFA41-F327-40B8-8AA4-1D60E214C3D1")
        let title = app.staticTexts["learningItemTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Jeg forstår.")

        app.buttons["revealButton"].tap()
        XCTAssertEqual(app.staticTexts["translationText"].label, "I understand.")
    }

    func testLibrarySearchOpensDetailAndStudyCard() {
        launch()
        app.buttons["Library"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 3))

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("understand")

        let result = app.staticTexts["å forstå"]
        XCTAssertTrue(result.waitForExistence(timeout: 3))
        result.tap()

        let studyButton = app.buttons["studyItemButton"]
        for _ in 0..<4 where !studyButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(studyButton.waitForExistence(timeout: 3))

        let windowFrame = app.windows.firstMatch.frame
        let leadingInset = studyButton.frame.minX - windowFrame.minX
        let trailingInset = windowFrame.maxX - studyButton.frame.maxX
        XCTAssertEqual(leadingInset, trailingInset, accuracy: 2)
        XCTAssertEqual(studyButton.frame.midX, windowFrame.midX, accuracy: 2)

        studyButton.tap()

        XCTAssertTrue(app.buttons["Learn"].firstMatch.isSelected)
        XCTAssertEqual(app.staticTexts["learningItemTitle"].label, "å forstå")
    }

    func testReviewAndProgressTabsLoad() {
        launch()
        app.buttons["Review"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 3))

        app.buttons["Progress"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Local database"].exists)
        XCTAssertFalse(app.staticTexts["Content packs"].exists)
        XCTAssertFalse(app.staticTexts["Content pack"].exists)
    }

    func testPrivacyTermsAndAcknowledgementsAreAccessible() {
        launch()
        app.buttons["Progress"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 3))

        let legalLink = app.buttons["aboutPrivacyLink"]
        for _ in 0..<6 where !legalLink.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(legalLink.waitForExistence(timeout: 3))
        legalLink.tap()

        XCTAssertTrue(app.navigationBars["About & Privacy"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Privacy policy"].exists)

        let standardEULA = app.descendants(matching: .any)["Apple Standard EULA"]
        for _ in 0..<5 where !standardEULA.exists {
            app.swipeUp()
        }
        XCTAssertTrue(standardEULA.waitForExistence(timeout: 3))

        let acknowledgements = app.staticTexts["Acknowledgements"]
        for _ in 0..<4 where !acknowledgements.exists {
            app.swipeUp()
        }
        XCTAssertTrue(acknowledgements.waitForExistence(timeout: 3))
    }

    func testPreviousReturnsToPriorCard() {
        launch(deepLink: "norskword://word/8F18F091-321C-4EF2-A094-BAA95ED0E663")
        XCTAssertEqual(app.staticTexts["learningItemTitle"].label, "å forstå")

        let next = app.buttons["nextItemButton"]
        for _ in 0..<5 where !next.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        next.tap()

        let previous = app.buttons["previousItemButton"]
        XCTAssertTrue(previous.waitForExistence(timeout: 3))
        previous.tap()
        for _ in 0..<5 where !app.staticTexts["learningItemTitle"].isHittable {
            app.swipeDown()
        }
        XCTAssertEqual(app.staticTexts["learningItemTitle"].label, "å forstå")
    }

    func testPhraseBuilderAcceptsCorrectOrder() {
        launch(deepLink: "norskword://phrase/4AABFA41-F327-40B8-8AA4-1D60E214C3D1")
        app.buttons["revealButton"].tap()

        let firstToken = app.buttons["phraseBuilderToken_0"]
        for _ in 0..<7 where !firstToken.exists {
            app.swipeUp()
        }
        XCTAssertTrue(firstToken.waitForExistence(timeout: 3))
        firstToken.tap()
        app.buttons["phraseBuilderToken_1"].tap()
        app.buttons["checkPhraseOrder"].tap()
        XCTAssertEqual(app.staticTexts["phraseBuilderFeedback"].label, "Correct order")
    }

    func testVestlandSearchFindsKoffer() {
        launch()
        app.buttons["Library"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 3))

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("koffer")

        let result = app.staticTexts["koffer"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 3))
        result.tap()
        XCTAssertTrue(app.staticTexts["Vestland speech"].waitForExistence(timeout: 3))
    }

    private func launch(deepLink: String? = nil) {
        if let deepLink {
            app.launchArguments.append(deepLink)
        }
        app.launch()
    }
}
