# Footer Action Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the refresh and exit actions visually recognizable as buttons without changing the compact footer layout.

**Architecture:** Add one private reusable SwiftUI `ButtonStyle` in `PopoverView.swift`. Apply it to the existing refresh and exit buttons with theme-accent and neutral tints while preserving their actions and states.

**Tech Stack:** Swift 6, SwiftUI, AppKit, macOS 13+

## Global Constraints

- Keep the footer at exactly `42pt` and the popover at exactly `348 × 404`.
- Preserve all existing actions, labels, cards, animation, and data behavior.
- Use independent `24pt` high rounded button frames with `7pt` corners and `8pt` horizontal padding.
- Do not commit or push.

---

### Task 1: Add Framed Footer Actions

**Files:**
- Modify: `Sources/CodexMochiApp/PopoverView.swift`

**Interfaces:**
- Consumes: the existing refresh and exit `Button` labels plus `MochiPalette.accent(for:)` and `MochiPalette.secondaryInk`
- Produces: `FooterActionButtonStyle` and two visibly framed footer actions

- [x] **Step 1: Verify the new style is absent**

Run:

```bash
! rg -n 'FooterActionButtonStyle' Sources/CodexMochiApp/PopoverView.swift
```

Expected: the command exits successfully because the required style is not implemented yet; the positive acceptance assertion `rg -n 'FooterActionButtonStyle' ...` fails.

- [x] **Step 2: Implement and apply the button style**

Add a private `FooterActionButtonStyle: ButtonStyle` that gives its label `8pt` horizontal padding, a fixed `24pt` height, a continuous rounded rectangle with `7pt` corners, an 8% tint fill, and a 26% tint stroke. Increase fill and stroke opacity while pressed.

Apply the style to refresh with `MochiPalette.accent(for: theme)` and to exit with `MochiPalette.secondaryInk`. Keep the refresh task, disabled state, exit termination action, icon, and labels unchanged.

- [x] **Step 3: Verify the source criteria**

Run:

```bash
rg -n 'FooterActionButtonStyle|frame\(height: 24\)|cornerRadius: 7' Sources/CodexMochiApp/PopoverView.swift
rg -n 'frame\(height: 42\)|height: 404' Sources/CodexMochiApp/PopoverView.swift Sources/CodexMochiApp/StatusBarController.swift
```

Expected: the reusable style and both unchanged layout heights are present.

- [x] **Step 4: Run complete verification and replace the app**

```bash
swift test
./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 dist/CodexMochi.app
plutil -lint dist/CodexMochi.app/Contents/Info.plist
git diff --check
```

Expected: 33 tests pass; build, signing, plist, and whitespace checks succeed. Restart the exact `dist/CodexMochi.app` process and verify its launch time is newer than the rebuilt executable.
