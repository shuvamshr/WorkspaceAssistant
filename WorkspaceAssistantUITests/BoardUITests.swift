import XCTest

/// End-to-end checks of manual task management, using in-memory storage.
final class BoardUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAddTaskManually() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestScriptedAssistant"]
        app.launch()

        app.buttons["New Task"].firstMatch.tap()
        let title = app.descendants(matching: .any)["taskTitleField"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Code review")
        app.buttons["Add"].tap()

        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Code review")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "New task tile should appear on the board")
    }
}
