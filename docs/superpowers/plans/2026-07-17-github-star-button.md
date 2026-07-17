# GitHub Star Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a compact Star button before refresh that opens the Codex Mochi GitHub repository in the default browser.

**Architecture:** Define the canonical project URL in the core target so it can be verified independently. The existing SwiftUI footer consumes that URL through `NSWorkspace`, reuses `FooterActionButtonStyle`, and leaves all existing footer actions unchanged.

**Tech Stack:** Swift 6, Foundation, SwiftUI, AppKit, macOS 13+

## Global Constraints

- Use the exact URL `https://github.com/Exusty/codex-mochi`.
- Order footer actions as `Star → 刷新 → 退出`.
- Keep the footer at `42pt` and the popover at `348 × 404`.
- Reuse the existing `24pt` framed footer button style.
- Do not change existing refresh, exit, status, cards, themes, or data behavior.
- Do not commit or push automatically.

---

### Task 1: Project Link and Star Action

**Files:**
- Create: `Sources/CodexMochiCore/ProjectLinks.swift`
- Create: `Tests/CodexMochiCoreTests/ProjectLinksTests.swift`
- Modify: `Sources/CodexMochiApp/PopoverView.swift`

**Interfaces:**
- Produces: `CodexMochiLinks.githubProject: URL`
- Consumes: `NSWorkspace.shared.open(CodexMochiLinks.githubProject)`

- [x] **Step 1: Write the failing project-link test**

```swift
import Testing
@testable import CodexMochiCore

@Test func githubProjectLinkTargetsThePublicRepository() {
    #expect(CodexMochiLinks.githubProject.absoluteString == "https://github.com/Exusty/codex-mochi")
    #expect(CodexMochiLinks.githubProject.host == "github.com")
}
```

- [x] **Step 2: Run the focused test and verify RED**

Run: `swift test --filter githubProjectLinkTargetsThePublicRepository`

Expected: compilation fails because `CodexMochiLinks` does not exist.

- [x] **Step 3: Implement the canonical URL**

```swift
import Foundation

public enum CodexMochiLinks {
    public static let githubProject = URL(string: "https://github.com/Exusty/codex-mochi")!
}
```

- [x] **Step 4: Add the Star button before refresh**

Insert a `Button` before the existing refresh button. Its label is `Label("Star", systemImage: "star.fill")` using the existing 10-point semibold font. Its action calls `NSWorkspace.shared.open(CodexMochiLinks.githubProject)`, and it uses `FooterActionButtonStyle(tint: MochiPalette.membershipButter)` plus an explanatory help and accessibility label.

- [x] **Step 5: Verify and replace the local app**

```bash
swift test
./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
git diff --check
```

Expected: all tests pass; build, signing, plist, and whitespace checks succeed. Restart the exact workspace app and verify only one fresh process remains.
