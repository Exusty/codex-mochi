# Codex Mochi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native, cute, practical macOS menu bar app that displays honest Codex five-hour and weekly remaining quota.

**Architecture:** A dependency-free Swift package separates quota/auth/network behavior into `CodexMochiCore` and AppKit presentation into `CodexMochiApp`. A release packaging script wraps the executable in an accessory `.app` bundle.

**Tech Stack:** Swift 6.1, Foundation, AppKit, SwiftUI, XCTest, Swift Package Manager

## Global Constraints

- Support macOS 13 and newer.
- Show remaining quota, not used quota.
- Read existing Codex credentials locally and never persist or log secrets.
- Query only `https://chatgpt.com/backend-api/wham/usage`.
- Use no third-party runtime dependencies.
- Show honest loading, signed-out, stale, and unavailable states.

---

### Task 1: Core quota model and parser

**Files:**
- Create: `Package.swift`
- Create: `Tests/CodexMochiCoreTests/QuotaParserTests.swift`
- Create: `Sources/CodexMochiCore/QuotaModels.swift`
- Create: `Sources/CodexMochiCore/QuotaParser.swift`
- Create: `Sources/CodexMochiCore/AuthLoader.swift`

**Interfaces:**
- Produces: `QuotaWindow`, `QuotaSnapshot`, `QuotaLevel`, `QuotaParser.parse(data:)`, and `AuthLoader.accountID(fromJWT:)`.

- [ ] **Step 1: Write parser and auth tests first**

Create tests that require ratio-to-percent conversion, used-to-remaining conversion, range clamping, reset parsing, level thresholds, and JWT account ID extraction.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test`

Expected: compilation fails because `QuotaParser`, `QuotaLevel`, and `AuthLoader` do not exist.

- [ ] **Step 3: Implement the smallest core model/parser/auth API**

Implement the tested public interfaces. Parse common primary/secondary and five-hour/weekly field names, accept numeric epoch reset timestamps, and clamp percentages to `0...100`.

- [ ] **Step 4: Run tests and verify GREEN**

Run: `swift test`

Expected: all `CodexMochiCoreTests` pass with zero failures.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/CodexMochiCore Tests/CodexMochiCoreTests
git commit -m "feat: add Codex quota core"
```

### Task 2: Network client and refresh store

**Files:**
- Create: `Tests/CodexMochiCoreTests/QuotaClientTests.swift`
- Create: `Sources/CodexMochiCore/QuotaClient.swift`
- Create: `Sources/CodexMochiCore/QuotaStore.swift`

**Interfaces:**
- Consumes: `QuotaParser.parse(data:)`, `AuthLoader.load()`.
- Produces: `QuotaFetching.fetch()`, `QuotaClient.fetch()`, and main-actor `QuotaStore.refresh()` state.

- [ ] **Step 1: Write URL protocol tests for headers, status mapping, and response-size rejection**
- [ ] **Step 2: Run `swift test` and verify the new tests fail for missing client APIs**
- [ ] **Step 3: Implement a one-megabyte bounded URLSession request and a store that retains stale successful data on failure**
- [ ] **Step 4: Run `swift test` and verify all tests pass**
- [ ] **Step 5: Commit with `git commit -m "feat: fetch Codex quota safely"`**

### Task 3: Menu bar mascot and popover

**Files:**
- Create: `Sources/CodexMochiApp/main.swift`
- Create: `Sources/CodexMochiApp/AppDelegate.swift`
- Create: `Sources/CodexMochiApp/StatusBarController.swift`
- Create: `Sources/CodexMochiApp/MochiStatusView.swift`
- Create: `Sources/CodexMochiApp/PopoverView.swift`

**Interfaces:**
- Consumes: observable `QuotaStore` state and `QuotaLevel`.
- Produces: accessory `NSApplication`, animated status item, SwiftUI popover, Refresh and Quit actions.

- [ ] **Step 1: Add a status-title formatting test and verify it fails**
- [ ] **Step 2: Implement the formatter and verify the focused test passes**
- [ ] **Step 3: Implement the compact vector mochi-cat view with blink/bob animation speed derived from remaining quota**
- [ ] **Step 4: Implement the 320-point popover with mascot, two quota cards, reset labels, refresh state, Refresh, and Quit**
- [ ] **Step 5: Run `swift test` and `swift build -c release` and require zero failures**
- [ ] **Step 6: Commit with `git commit -m "feat: add animated menu bar companion"`**

### Task 4: App packaging and handoff

**Files:**
- Create: `scripts/build_app.sh`
- Create: `Resources/Info.plist`
- Create: `README.md`
- Create: `.gitignore`

**Interfaces:**
- Consumes: `.build/release/CodexMochi`.
- Produces: `dist/CodexMochi.app` with `Contents/MacOS/CodexMochi` and `LSUIElement=true`.

- [ ] **Step 1: Write the bundle metadata and packaging script**
- [ ] **Step 2: Run `./scripts/build_app.sh` and inspect `plutil -p dist/CodexMochi.app/Contents/Info.plist`**
- [ ] **Step 3: Launch the bundle, verify a live process after three seconds, then terminate that smoke-test process**
- [ ] **Step 4: Run final `swift test` and `swift build -c release` from a clean process**
- [ ] **Step 5: Document build, run, privacy, and Gatekeeper expectations in README**
- [ ] **Step 6: Commit with `git commit -m "build: package Codex Mochi app"`**
