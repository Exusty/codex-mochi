# Popping Kibble Burst Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rotating food bowl with speed-sensitive kibble and spark particles that burst outward and fade.

**Architecture:** `CodexMochiCore` owns a deterministic `FoodBurstStyle` mapping from `TokenSpeedMood` to particle counts, timing, and travel strength. SwiftUI owns rendering: a stable bowl plus deterministic particle slots animated by `TimelineView`, with all movement disabled when Reduce Motion is active.

**Tech Stack:** Swift 6, SwiftUI, macOS 13+, Swift Testing

## Global Constraints

- Keep the bowl stable; no rotation or shaking.
- Kibble flies outward and fades instead of falling back into the bowl.
- `gobbling` adds short sparks; `flying` adds denser kibble and long outward sparks.
- Use deterministic particle slots to avoid per-frame random flicker.
- Reduce Motion renders a static bowl with no moving particles.
- Preserve themes, reset cards, quota cards, and clickable cat behavior.
- Keep all changes local: do not commit or push.

---

### Task 1: Testable Burst Style

**Files:**
- Modify: `Sources/CodexMochiCore/MochiPresentation.swift`
- Modify: `Tests/CodexMochiCoreTests/MochiPresentationTests.swift`

**Interfaces:**
- Consumes: `TokenSpeedMood`
- Produces: `FoodBurstStyle.init(mood:)`, `kibbleCount`, `sparkCount`, `cycleDuration`, `travelStrength`

- [ ] **Step 1: Replace the rotation assertions with failing burst-style assertions**

```swift
#expect(FoodBurstStyle(mood: .learning) == .still)
#expect(FoodBurstStyle(mood: .nibbling).kibbleCount == 1)
#expect(FoodBurstStyle(mood: .munching).kibbleCount == 3)
#expect(FoodBurstStyle(mood: .gobbling).sparkCount > 0)
#expect(FoodBurstStyle(mood: .flying).sparkCount > FoodBurstStyle(mood: .gobbling).sparkCount)
#expect(FoodBurstStyle(mood: .flying).travelStrength > FoodBurstStyle(mood: .gobbling).travelStrength)
```

- [ ] **Step 2: Run the focused test and verify it fails because `FoodBurstStyle` does not exist**

Run: `swift test --filter MochiPresentationTests`

Expected: compilation failure naming the missing `FoodBurstStyle` type.

- [ ] **Step 3: Implement the minimal burst-style mapping**

```swift
public enum FoodBurstStyle: Equatable, Sendable {
    case still, tiny, popping, sparkling, firework

    public init(mood: TokenSpeedMood) {
        switch mood {
        case .learning, .resting: self = .still
        case .nibbling: self = .tiny
        case .munching: self = .popping
        case .gobbling: self = .sparkling
        case .flying: self = .firework
        }
    }

    public var kibbleCount: Int {
        switch self {
        case .still: 0
        case .tiny: 1
        case .popping: 3
        case .sparkling: 5
        case .firework: 8
        }
    }

    public var sparkCount: Int {
        switch self {
        case .still, .tiny, .popping: 0
        case .sparkling: 3
        case .firework: 7
        }
    }

    public var cycleDuration: Double? {
        switch self {
        case .still: nil
        case .tiny: 1.8
        case .popping: 1.25
        case .sparkling: 0.8
        case .firework: 0.48
        }
    }

    public var travelStrength: Double {
        switch self {
        case .still: 0
        case .tiny: 0.45
        case .popping: 0.7
        case .sparkling: 0.95
        case .firework: 1.35
        }
    }
}
```

- [ ] **Step 4: Run the focused test and require all burst assertions to pass**

Run: `swift test --filter MochiPresentationTests`

Expected: all `MochiPresentationTests` pass.

### Task 2: Stable Bowl and Outward Particles

**Files:**
- Modify: `Sources/CodexMochiApp/PopoverView.swift`

**Interfaces:**
- Consumes: `FoodBurstStyle`, `TokenSpeedMood`, `MochiThemeID`
- Produces: `PoppingFoodBowl`, deterministic kibble slots, deterministic spark slots

- [ ] **Step 1: Replace `SpinningFoodBowl` with `PoppingFoodBowl` at the token card call site**

```swift
PoppingFoodBowl(mood: snapshot.speedMood, theme: theme)
    .frame(width: 56, height: 56)
```

- [ ] **Step 2: Render a stable `FoodBowlGraphic` and deterministic particle slots**

Use the timeline cycle phase to calculate each slot's local progress. Kibble starts at the bowl rim, moves along a fixed outward vector with a small upward arc, scales down, and fades to zero. Sparks render only for `sparkling` and `firework` as tapered capsules aligned with their outward vectors.

- [ ] **Step 3: Enforce Reduce Motion**

When `accessibilityReduceMotion` is true, skip all kibble and spark views and render only `FoodBowlGraphic`.

- [ ] **Step 4: Compile the app**

Run: `swift build`

Expected: build exits 0 with no references to `SpinningFoodBowl` or `FoodBowlMotion`.

### Task 3: Documentation and Local Delivery

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: completed burst animation behavior
- Produces: accurate feature description and a verified local `.app`

- [ ] **Step 1: Update the README animation description**

Replace “猫粮碗逐级加速旋转” with wording that describes outward popping kibble, sparks at fast speed, and direct spark spray at very fast speed.

- [ ] **Step 2: Run the full test and packaging gates**

Run:

```bash
swift test
./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
git diff --check
```

Expected: 0 test failures, release build succeeds, signature is valid, plist is valid, and diff check exits 0.

- [ ] **Step 3: Replace the running local process**

Terminate only the existing `CodexMochi` executable, open `dist/CodexMochi.app`, wait three seconds, and verify `pgrep -fl CodexMochi` points to the current workspace bundle.

- [ ] **Step 4: Confirm the work remains local**

Run: `git status --short && git branch --show-current`

Expected: local modifications remain on `codex/weekly-rate`; no commit or push occurs.
