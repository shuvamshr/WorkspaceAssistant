import XCTest

/// Runs Xcode's automated accessibility audit on the main screens.
final class AccessibilityAuditTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-UITestScriptedAssistant"]
        app.launch()
    }

    @MainActor
    private func audit(_ screen: String) {
        do {
            try app.performAccessibilityAudit { issue in
                if Self.isAccepted(issue) { return true }
                let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)' id=\($0.identifier)" } ?? "nil"
                XCTFail("[\(screen)] \(issue.auditType): \(issue.compactDescription) — \(element)")
                return true
            }
        } catch {
            XCTFail("Audit failed on \(screen): \(error)")
        }
    }

    /// Known, reviewed exceptions (see docs/accessibility.md):
    /// - "Nearly passed" contrast: system secondary label colours on grouped backgrounds.
    /// - Contrast with no element: system placeholder text in empty text fields.
    /// - "Partially unsupported" Dynamic Type: text verified to scale and wrap up to AX5 by screenshot review.
    /// - Clipped text on `Toggle` labels: the system toggle row at the largest sizes.
    @MainActor
    private static func isAccepted(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        let description = issue.compactDescription
        switch issue.auditType {
        case .contrast:
            return description.contains("nearly passed") || issue.element == nil
        case .dynamicType:
            return description.contains("partially")
        case .textClipped:
            return ["High Priority", "Completed"].contains(issue.element?.label ?? "")
        default:
            return false
        }
    }

    @MainActor
    func testBoardGrid() {
        audit("grid")
    }

    @MainActor
    func testTaskDetail() {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Refactor Network Layer")).firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["taskTitleField"].firstMatch.waitForExistence(timeout: 5))
        audit("detail")
    }

    @MainActor
    func testAssistantWithTranscript() {
        app.buttons["askAssistantButton"].firstMatch.tap()
        app.buttons["Prioritise the network refactor and switch to Focus"].firstMatch.tap()
        let block = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Assistant prioritised Refactor Network Layer")).firstMatch
        XCTAssertTrue(block.waitForExistence(timeout: 5))
        // Expand the sheet so no transcript content sits under the translucent header.
        let header = app.navigationBars["Assistant"].firstMatch
        let top = app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        header.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.2, thenDragTo: top)
        sleep(2)
        audit("assistant")
    }

    @MainActor
    func testOtherLayouts() {
        for layout in ["Focus", "List", "Board"] {
            app.buttons["View Options"].firstMatch.tap()
            app.buttons[layout].firstMatch.tap()
            audit(layout.lowercased())
        }
    }
}
