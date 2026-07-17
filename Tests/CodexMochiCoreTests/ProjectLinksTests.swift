import Testing
@testable import CodexMochiCore

@Test func githubProjectLinkTargetsThePublicRepository() {
    #expect(CodexMochiLinks.githubProject.absoluteString == "https://github.com/Exusty/codex-mochi")
    #expect(CodexMochiLinks.githubProject.host == "github.com")
}
