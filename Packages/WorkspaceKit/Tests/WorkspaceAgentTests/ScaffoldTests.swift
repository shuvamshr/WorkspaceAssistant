import Testing
@testable import WorkspaceAgent

@Test func moduleLoads() {
    #expect(WorkspaceAgentModule.name == "WorkspaceAgent")
}
