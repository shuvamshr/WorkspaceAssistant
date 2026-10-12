import XCTest

/// Drives the scripted assistant end to end and checks that the board changes.
final class AssistantUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testSuggestionPrioritisesAndSwitchesToFocus() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestScriptedAssistant"]
        app.launch()

        app.buttons["askAssistantButton"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["simulatedAssistantBanner"].firstMatch.waitForExistence(timeout: 5),
                      "The simulated assistant must be labelled")

        app.buttons["Prioritise the network refactor and switch to Focus"].firstMatch.tap()

        // The transcript shows the action block for the tool call.
        let block = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Assistant prioritised Refactor Network Layer")).firstMatch
        XCTAssertTrue(block.waitForExistence(timeout: 5))

        // Close the assistant and check the board: Focus layout with the task as high priority.
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Everything Else"].waitForExistence(timeout: 5), "Board should be in Focus layout")
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Refactor Network Layer", "high priority")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Task should be high priority")
    }

    @MainActor
    func testTypedPromptSwitchesLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestScriptedAssistant"]
        app.launch()

        app.buttons["askAssistantButton"].firstMatch.tap()
        let composer = app.descendants(matching: .any)["assistantComposer"].firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("Switch to List view")
        app.buttons["assistantSendButton"].firstMatch.tap()

        let block = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Assistant switched layout to List")).firstMatch
        XCTAssertTrue(block.waitForExistence(timeout: 5))
    }
}
