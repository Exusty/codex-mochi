# Remove Popover Blank Space Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the unused vertical area below the three information cards without changing any visible content or interaction.

**Architecture:** Keep the existing SwiftUI hierarchy and replace the expanding spacer with a fixed six-point gap. Set the SwiftUI root and AppKit popover container to the same `348 × 404` dimensions so neither layer reintroduces blank space.

**Tech Stack:** Swift 6, SwiftUI, AppKit, macOS 13+

## Global Constraints

- Keep the width at exactly `348pt`.
- Set both view and popover heights to exactly `404pt`.
- Preserve every existing card, control, animation, style, and data path.
- Do not commit or push.

---

### Task 1: Make the Popover Content-Fit

**Files:**
- Modify: `Sources/CodexMochiApp/PopoverView.swift`
- Modify: `Sources/CodexMochiApp/StatusBarController.swift`

**Interfaces:**
- Consumes: the existing `header`, three-card stack, and `compactFooter`
- Produces: a fixed `348 × 404` popover with a six-point card-to-footer gap

- [x] **Step 1: Record the current source assertions**

Run:

```bash
rg -n 'Spacer\(minLength: 6\)|height: 500' Sources/CodexMochiApp/PopoverView.swift Sources/CodexMochiApp/StatusBarController.swift
```

Expected: one expanding spacer and two `500`-point height declarations are present.

- [x] **Step 2: Apply the minimal layout change**

In `PopoverView`, replace:

```swift
Spacer(minLength: 6)
```

with:

```swift
Color.clear.frame(height: 6)
```

Change the root view to:

```swift
.frame(width: 348, height: 404, alignment: .top)
```

Change the AppKit container to:

```swift
popover.contentSize = NSSize(width: 348, height: 404)
```

- [x] **Step 3: Verify source-level acceptance criteria**

Run:

```bash
rg -n 'height: 404' Sources/CodexMochiApp/PopoverView.swift Sources/CodexMochiApp/StatusBarController.swift
! rg -n 'Spacer\(minLength: 6\)|height: 500' Sources/CodexMochiApp/PopoverView.swift Sources/CodexMochiApp/StatusBarController.swift
```

Expected: both `404`-point declarations are found and the expanding spacer/old height are absent.

- [x] **Step 4: Run complete verification**

```bash
swift test
./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
git diff --check
```

Expected: all tests pass; packaging, signing, plist, and whitespace checks exit successfully.

- [x] **Step 5: Replace the running local app**

Terminate only the current `CodexMochi` process, open `dist/CodexMochi.app`, wait briefly, and verify the running executable resolves to this workspace. Leave all changes uncommitted and unpushed.
