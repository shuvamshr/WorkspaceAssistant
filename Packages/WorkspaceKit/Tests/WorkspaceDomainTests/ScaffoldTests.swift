import Testing
@testable import WorkspaceDomain

@Test func moduleLoads() {
    #expect(WorkspaceDomainModule.name == "WorkspaceDomain")
}
