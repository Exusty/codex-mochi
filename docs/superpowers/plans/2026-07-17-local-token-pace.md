# CodexMochi Local Token Pace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show today's raw Codex Token usage on this Mac and a cute recent Token-speed state in the existing menu bar popover.

**Architecture:** Add a focused `LocalTokenUsage` core unit that parses persisted Codex JSONL `token_count` events, aggregates positive cumulative deltas for the local calendar day, and calculates a 15-minute hourly rate. `QuotaStore` refreshes this snapshot alongside quota data, while SwiftUI renders a separate Token card so raw Token rate is never confused with official quota percentage.

**Tech Stack:** Swift 6, Foundation JSON decoding, Swift Testing, SwiftUI, macOS 13+

## Global Constraints

- Read only from `~/.codex/sessions`; never modify or upload Codex logs.
- “Today” starts at local-calendar midnight in the user's current time zone.
- Raw Token counts must be labeled as local raw Token, not official quota Token.
- Missing directories, unreadable files, malformed JSONL lines, and empty data produce an honest empty state.
- Keep all work local and uncommitted; do not push GitHub.

---

### Task 1: Local Token log aggregation and pace model

**Files:**
- Create: `Sources/CodexMochiCore/LocalTokenUsage.swift`
- Create: `Tests/CodexMochiCoreTests/LocalTokenUsageTests.swift`

**Interfaces:**
- Produces: `TokenCounts`, `LocalTokenEvent`, `LocalTokenSnapshot`, `TokenSpeedMood`, `LocalTokenUsageCalculator.calculate(events:now:calendar:recentWindow:)`, and `LocalTokenLogReader.read(now:calendar:)`.
- `LocalTokenSnapshot` exposes today's category totals, `recentTokensPerHour`, `speedMood`, and `lastUpdatedAt` for the UI and store.

- [ ] **Step 1: Write failing aggregation tests**

Cover these concrete cases using in-memory `LocalTokenEvent` values:

```swift
@Test func aggregatesPositiveCumulativeDeltasWithoutCountingDuplicates()
@Test func keepsOnlyEventsFromTheLocalCalendarDay()
@Test func calculatesRecentFifteenMinuteHourlyRate()
@Test func classifiesEveryCuteTokenSpeedBoundary()
```

Use events with cumulative totals `100 -> 160 -> 160 -> 25` and assert the daily total is `185`: the first session contributes 160 once and the cumulative reset contributes 25 without subtracting.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter LocalTokenUsageTests`

Expected: compilation fails because `LocalTokenEvent` and `LocalTokenUsageCalculator` do not exist.

- [ ] **Step 3: Implement the minimal aggregation model**

Implement:

```swift
public struct TokenCounts: Codable, Equatable, Sendable {
    public let input: Int64
    public let cachedInput: Int64
    public let output: Int64
    public let reasoningOutput: Int64
    public let total: Int64
}

public struct LocalTokenEvent: Equatable, Sendable {
    public let sessionID: String
    public let date: Date
    public let cumulative: TokenCounts
}

public enum TokenSpeedMood: Equatable, Sendable {
    case learning, resting, nibbling, munching, gobbling, flying
}
```

Group events by `sessionID`, sort by time, and add the first cumulative value plus later positive deltas. When a cumulative category decreases, treat the new value as a reset and add it. Calculate the 15-minute rate as recent positive total deltas divided by the observed fraction of an hour, capped to the configured recent window.

- [ ] **Step 4: Implement the JSONL reader**

Scan the current local day directory plus the previous day's directory to support sessions crossing midnight. Decode only lines where:

```text
type == event_msg
payload.type == token_count
payload.info.total_token_usage exists
```

Use the rollout filename as `sessionID`, skip malformed lines, and return `[]` when the root is missing or unreadable.

- [ ] **Step 5: Run focused and full tests**

Run: `swift test --filter LocalTokenUsageTests && swift test`

Expected: all new tests and the existing 17 tests pass with zero failures.

### Task 2: Store refresh, Token card, and local replacement

**Files:**
- Modify: `Sources/CodexMochiCore/QuotaStore.swift`
- Modify: `Sources/CodexMochiApp/PopoverView.swift`
- Modify: `Sources/CodexMochiApp/StatusBarController.swift`
- Modify: `Sources/CodexMochiApp/MochiIconRenderer.swift`
- Modify: `README.md`
- Test: `Tests/CodexMochiCoreTests/QuotaClientTests.swift`

**Interfaces:**
- Consumes: `LocalTokenLogReader.read(now:calendar:)` and `LocalTokenUsageCalculator.calculate(...)` from Task 1.
- Produces: `QuotaStore.localTokens`, refreshed at initialization and on each quota refresh.

- [ ] **Step 1: Write a failing store test**

Add a test-only injected `tokenSnapshotProvider` to the desired initializer API and assert `QuotaStore.refresh()` publishes the supplied `LocalTokenSnapshot` even when quota fetching succeeds independently.

- [ ] **Step 2: Run the store test and verify RED**

Run: `swift test --filter quotaStoreRefreshesLocalTokenSnapshot`

Expected: compilation fails because the initializer and `localTokens` property do not exist.

- [ ] **Step 3: Add local Token refresh to `QuotaStore`**

Add:

```swift
@Published public private(set) var localTokens: LocalTokenSnapshot
private let tokenSnapshotProvider: @Sendable () -> LocalTokenSnapshot
```

Refresh local Token data before the remote quota request so local stats still update when the network request fails. Keep the existing initializer defaults usable by production and existing tests.

- [ ] **Step 4: Add the Token card and cute speed copy**

Insert `LocalTokenCard(snapshot:)` between quota cards and `PaceCard`. Show:

- `今日 Mac 口粮`
- compact total such as `2,890 万`
- `最近 15 分钟` rate such as `1,584 万 / 时`
- input/cache/output compact breakdown
- mood copy from `TokenSpeedMood`
- footnote `本机原始 Token · 不等于额度 Token`

Use a pale sky-blue card distinct from the mint quota-pace card. Increase popover height only as much as required and retain the current 348-point width.

- [ ] **Step 5: Connect motion without overriding quota warnings**

Expose `TokenSpeedMood.animationUrgency`. For the menu bar and popover mascot, use the maximum of quota pace urgency and Token speed urgency. Token activity may speed up the cat, while quota remaining color still communicates risk.

- [ ] **Step 6: Update documentation**

Add local raw Token totals, 15-minute Token speed, privacy boundary, and the limitation that other devices or unpersisted sessions may be absent.

- [ ] **Step 7: Verify and replace the local app**

Run:

```bash
swift test
./scripts/build_app.sh
git diff --check
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
```

Expected: all tests pass, release build succeeds, diff check is clean, signature is valid, and the plist is valid.

Terminate only the running CodexMochi process, launch `dist/CodexMochi.app`, wait five seconds, and verify the new process path. Confirm `git status` still shows local uncommitted changes and no commit or push occurred.
