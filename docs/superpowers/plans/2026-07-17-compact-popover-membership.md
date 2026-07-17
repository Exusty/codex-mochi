# Compact Popover and Membership Badge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `348 × 500` Codex Mochi popover without the weekly pace card and add a persistent, manually correctable membership badge.

**Architecture:** A new core membership presentation type converts the existing plan string into an honest tier and resolves an optional local override. SwiftUI uses `@AppStorage` for the override, compacts the existing single-column hierarchy, merges status and actions into one footer, and keeps pace calculations internal for cat and menu-bar motion.

**Tech Stack:** Swift 6, SwiftUI, AppKit, macOS 13+, Swift Testing

## Global Constraints

- Fix both the popover controller and root view to `348 × 500`.
- Remove `PaceCard` from the UI while preserving `UsagePace` sampling and animation inputs.
- Preserve the quota card, reset-card data, local Token data, theme menu, clickable cat, popping kibble, refresh, exit, and error states.
- Treat raw `pro` as generic Pro; never guess Pro 5x or Pro 20x.
- Persist only the display override in `UserDefaults`; add no network request and save no credential or account identifier.
- Use the approved tier symbols and semantic colors.
- Keep changes local; do not commit or push.

---

### Task 1: Membership Tier Model

**Files:**
- Create: `Sources/CodexMochiCore/MembershipPresentation.swift`
- Create: `Tests/CodexMochiCoreTests/MembershipPresentationTests.swift`

**Interfaces:**
- Consumes: the existing display plan string from `QuotaSnapshot.plan`
- Produces: `MembershipTier.detect(plan:)`, `MembershipOverride`, and `MembershipTier.resolved(detected:override:)`

- [ ] **Step 1: Write failing detection and override tests**

```swift
@Test func detectsMembershipWithoutGuessingGenericPro() {
    #expect(MembershipTier.detect(plan: "Plus") == .plus)
    #expect(MembershipTier.detect(plan: "pro") == .pro)
    #expect(MembershipTier.detect(plan: "pro-5x") == .pro5x)
    #expect(MembershipTier.detect(plan: "PRO 20X") == .pro20x)
    #expect(MembershipTier.detect(plan: nil) == .member)
}

@Test func manualMembershipOverrideWinsUntilAutomaticIsRestored() {
    #expect(MembershipTier.resolved(detected: .pro, override: .automatic) == .pro)
    #expect(MembershipTier.resolved(detected: .pro, override: .pro20x) == .pro20x)
    #expect(MembershipTier.resolved(detected: .plus, override: .pro5x) == .pro5x)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `swift test --filter MembershipPresentationTests`

Expected: compilation failure because `MembershipTier` and `MembershipOverride` do not exist.

- [ ] **Step 3: Implement the membership types**

```swift
public enum MembershipTier: Equatable, Sendable {
    case plus, pro, pro5x, pro20x, member

    public static func detect(plan: String?) -> MembershipTier {
        guard let plan else { return .member }
        let normalized = plan.lowercased().filter { $0.isLetter || $0.isNumber }
        if normalized.contains("pro20x") { return .pro20x }
        if normalized.contains("pro5x") { return .pro5x }
        if normalized == "pro" { return .pro }
        if normalized.contains("plus") { return .plus }
        return .member
    }

    public static func resolved(
        detected: MembershipTier,
        override: MembershipOverride
    ) -> MembershipTier {
        switch override {
        case .automatic: detected
        case .plus: .plus
        case .pro5x: .pro5x
        case .pro20x: .pro20x
        }
    }
}

public enum MembershipOverride: String, CaseIterable, Equatable, Sendable {
    case automatic, plus, pro5x, pro20x
}
```

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `swift test --filter MembershipPresentationTests`

Expected: both membership tests pass.

### Task 2: Compact Frontend

**Files:**
- Modify: `Sources/CodexMochiApp/PopoverView.swift`
- Modify: `Sources/CodexMochiApp/StatusBarController.swift`

**Interfaces:**
- Consumes: `MembershipTier`, `MembershipOverride`, `QuotaSnapshot.plan`
- Produces: `MembershipBadge`, a `348 × 500` popover, and compact card/footer layout

- [ ] **Step 1: Add persisted membership resolution to `PopoverView`**

```swift
@AppStorage("membershipOverride") private var storedMembershipOverride = MembershipOverride.automatic.rawValue

private var membershipOverride: MembershipOverride {
    MembershipOverride(rawValue: storedMembershipOverride) ?? .automatic
}

private var membership: MembershipTier {
    MembershipTier.resolved(
        detected: .detect(plan: store.snapshot?.plan),
        override: membershipOverride
    )
}
```

- [ ] **Step 2: Add the compact membership menu**

Build `MembershipBadge` as a borderless `Menu`. Its label uses `PLUS`, `PRO`, `PRO 5×`, `PRO 20×`, or `MEMBER`; its system image uses `plus`, `diamond.fill`, `bolt.fill`, `crown.fill`, or `person.crop.circle`; and its menu writes one of the four stable override raw values back to `@AppStorage`.

- [ ] **Step 3: Remove the weekly pace presentation**

Delete the `PaceCard` call and the private `PaceCard` and `PaceMetric` view types. Keep all `store.pace` uses in the header cat, caption, and status-bar renderer.

- [ ] **Step 4: Apply the approved compact metrics**

```swift
header
    .padding(.horizontal, 14)
    .padding(.top, 14)
    .padding(.bottom, 10)

VStack(spacing: 8) {
    QuotaCard(
        eyebrow: "本周额度",
        window: store.snapshot?.primaryWeekly,
        fallback: stateFallback
    )
    ResetCreditCard(
        available: store.snapshot?.resetCreditsAvailable,
        applicable: store.snapshot?.resetCreditsApplicable,
        fallback: stateFallback,
        theme: theme
    )
    LocalTokenCard(snapshot: store.localTokens, theme: theme)
}
.padding(.horizontal, 12)

compactFooter
    .padding(.horizontal, 14)
    .frame(height: 42)

.frame(width: 348, height: 500, alignment: .top)
```

Set the cat to `58 × 58`, headline to 21 points, card corner radius to 12, card padding to 10–11, and secondary copy to the ordinary system font. Merge the status dot/text, refresh, and exit into `compactFooter` while preserving a two-line error allowance.

- [ ] **Step 5: Set AppKit popover size and compile**

Change `popover.contentSize` to `NSSize(width: 348, height: 500)` and run `swift build`.

Expected: build exits 0; `rg -n "PaceCard|PaceMetric" Sources/CodexMochiApp` returns no matches.

### Task 3: Frontend Critique, Documentation, and Local Delivery

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: completed compact UI
- Produces: accurate documentation and a verified local `.app`

- [ ] **Step 1: Perform the frontend-design critique**

Check the implementation against the approved design: only cat plus popping kibble act as signature elements; all other surfaces are quiet; Plus, Pro 5x, and Pro 20x are distinguishable without relying on color alone; the three-card hierarchy stays legible at 348 points; and normal status text fits one line. Remove any decoration or spacing that does not encode information.

- [ ] **Step 2: Update README features and detection boundary**

Document the compact `348 × 500` popover, membership badge, generic-Pro honesty, and local manual Pro 5x/Pro 20x override.

- [ ] **Step 3: Run complete verification**

```bash
swift test
./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
git diff --check
rg -n "contentSize = NSSize\(width: 348, height: 500\)|frame\(width: 348, height: 500" Sources/CodexMochiApp
```

Expected: all tests pass, release packaging succeeds, signing and plist checks exit 0, diff check is clean, and both size declarations are present.

- [ ] **Step 4: Replace and verify the running local app**

Terminate only the running `CodexMochi` process, open `dist/CodexMochi.app`, wait three seconds, and require `pgrep -fl CodexMochi` to point at this workspace. Confirm `git branch --show-current` remains `codex/weekly-rate` and no commit or push occurred.
