# Interactive Mochi Theme and Reset Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add clickable cat reactions, eight persistent soft themes, a reset-credit card, and a Token-speed-driven animated food bowl to the existing CodexMochi popover.

**Architecture:** Extend the existing quota snapshot/parser with optional reset-credit counts from the same usage response. Put deterministic theme, cat-reaction, and bowl-motion mappings in a small tested core model; SwiftUI owns transient animation state and persists only the selected theme ID through `AppStorage`.

**Tech Stack:** Swift 6, Swift Testing, Foundation, SwiftUI, AppKit, macOS 13+

## Global Constraints

- Keep “本周额度 · 主窗口” and replace only the secondary card.
- Reset credits are display-only; no redemption request or account mutation.
- Theme selection persists locally and uses eight named soft colors.
- Quota warning semantics remain green/yellow/red and do not follow the theme.
- Respect Reduce Motion by stopping continuous bowl rotation.
- Keep all changes local and uncommitted; do not push GitHub.

---

### Task 1: Parse and model reset credits

**Files:**
- Modify: `Sources/CodexMochiCore/QuotaModels.swift`
- Modify: `Sources/CodexMochiCore/QuotaParser.swift`
- Modify: `Tests/CodexMochiCoreTests/QuotaParserTests.swift`
- Modify: `Tests/CodexMochiCoreTests/QuotaClientTests.swift`
- Modify: `Tests/CodexMochiCoreTests/StatusTitleFormatterTests.swift`

**Interfaces:**
- Produces: `QuotaSnapshot.resetCreditsAvailable: Int?` and `QuotaSnapshot.resetCreditsApplicable: Int?`.
- Existing snapshot initializers gain both optional fields with default `nil` so unrelated callers remain concise.

- [ ] **Step 1: Add failing parser tests**

Add fixtures asserting:

```swift
"rate_limit_reset_credits": {
  "available_count": 3,
  "applicable_available_count": 0
}
```

parses as `3` and `0`; a response without the object yields `nil` and `nil`; a partial object preserves the present field without inventing the missing one.

- [ ] **Step 2: Verify RED**

Run: `swift test --filter parsesPrimaryAndSecondaryAsWeeklyWindows`

Expected: compile failure because reset-credit snapshot properties do not exist.

- [ ] **Step 3: Add optional model fields and parser logic**

Read `rate_limit_reset_credits` or `rateLimitResetCredits`; use the existing numeric helper for `available_count`/`availableCount` and `applicable_available_count`/`applicableAvailableCount`. Clamp negative values to zero but keep absent fields `nil`.

- [ ] **Step 4: Update existing snapshot construction and run tests**

Run: `swift test`

Expected: all existing and reset-credit tests pass.

### Task 2: Theme, reaction, and food-bowl motion models

**Files:**
- Create: `Sources/CodexMochiCore/MochiPresentation.swift`
- Create: `Tests/CodexMochiCoreTests/MochiPresentationTests.swift`

**Interfaces:**
- Produces: `MochiThemeID`, `CatReaction`, and `FoodBowlMotion`.
- `MochiThemeID.init(storedValue:)` falls back to `.mint`; `CatReaction.next` cycles through five reactions; `FoodBowlMotion.init(mood:)` maps `TokenSpeedMood` to motion level and duration.

- [ ] **Step 1: Write failing presentation tests**

Cover:

```swift
@Test func exposesEightPersistentSoftThemes()
@Test func unknownStoredThemeFallsBackToMint()
@Test func catReactionsCycleInTheApprovedOrder()
@Test func mapsTokenSpeedToIncreasingFoodBowlMotion()
```

Assert the exact reaction order `.hearts -> .stars -> .blush -> .grin -> .tongue -> .hearts` and that flying duration is shorter than gobbling, which is shorter than munching.

- [ ] **Step 2: Verify RED**

Run: `swift test --filter MochiPresentationTests`

Expected: compile failure because the new presentation types do not exist.

- [ ] **Step 3: Implement deterministic presentation models**

Define eight stable raw string theme IDs and Chinese display names. Define reaction glyph/particle metadata without importing SwiftUI. Define bowl motion cases `still`, `sway`, `slowSpin`, `fastSpin`, `flying` with rotation durations `nil`, `2.4`, `1.4`, `0.65`, and `0.28` seconds.

- [ ] **Step 4: Run focused and full tests**

Run: `swift test --filter MochiPresentationTests && swift test`

Expected: all tests pass.

### Task 3: Interactive SwiftUI, theme menu, food bowl, and local replacement

**Files:**
- Modify: `Sources/CodexMochiApp/PopoverView.swift`
- Modify: `Sources/CodexMochiApp/StatusBarController.swift`
- Modify: `README.md`

**Interfaces:**
- Consumes: reset-credit snapshot fields, `MochiThemeID`, `CatReaction`, `FoodBowlMotion`, and existing `TokenSpeedMood`.
- Produces: clickable `InteractiveMochiFace`, `ThemePickerButton`, `ResetCreditCard`, and `SpinningFoodBowl` SwiftUI components.

- [ ] **Step 1: Add persistent theme selection**

Use `@AppStorage("mochiTheme") private var storedTheme = MochiThemeID.mint.rawValue`. Derive the validated theme and pass its accent colors to header, cat, reset card, Token card, and bowl. Render a small palette `Menu` beside the cat with eight color circles and checkmarks.

- [ ] **Step 2: Make the cat interactive**

Wrap `MochiFace` in a plain button. Store the current optional `CatReaction`, reaction index, bounce flag, and a generation counter. On click, advance the reaction, animate a spring bounce, show glyph particles, and schedule a 1.5-second reset that only executes if its generation is still current. When `hasError` is true, render the error eyes instead of reaction eyes.

- [ ] **Step 3: Replace the secondary quota card**

Render a soft-themed reset-card component with a ticket icon, large `N 张`, “储备重置卡” label, and `当前可使用 N 张`. If the count is absent, show an em dash and “暂未读到重置卡”. Do not include a redemption control.

- [ ] **Step 4: Add the animated food bowl to Token card**

Reserve a 64-point trailing column in `LocalTokenCard`. Draw a bowl, paw mark, six kibble dots, and conditional crumbs/wind lines using SwiftUI shapes. Use `FoodBowlMotion` duration for repeat-forever rotation; when `accessibilityReduceMotion` is true, keep rotation at zero and show only static particles appropriate to the mood.

- [ ] **Step 5: Fit and document the UI**

Keep the 348-point width and 690-point popover height. Compress Token text spacing if required rather than increasing height. Document interactions, eight themes, reset-card source, and Reduce Motion behavior in `README.md`.

- [ ] **Step 6: Verify and replace the local app**

Run:

```bash
swift test
./scripts/build_app.sh
git diff --check
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
```

Then terminate only `CodexMochi`, launch the rebuilt app, wait five seconds, and verify its path and process health. Confirm `origin/main...HEAD` remains `0 0` and all work is still uncommitted.
