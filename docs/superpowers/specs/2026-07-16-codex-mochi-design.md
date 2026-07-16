# Codex Mochi Design

## Product

Codex Mochi is a small, native macOS menu bar companion that makes Codex quota visible without opening another window. It combines an exact remaining-percentage readout with a tiny animated mascot inspired by RunCat's ambient, glanceable feedback.

The first version is intentionally narrow: Codex only, local credentials only, no telemetry, no account modification, and no settings window.

## Experience

- The app has no Dock icon and lives in the macOS menu bar.
- The status item shows a small hand-drawn mochi-cat face followed by the remaining percentage for the five-hour window.
- The cat blinks and bobs gently. Its animation becomes more urgent as remaining quota falls.
- Clicking the status item opens a compact native popover with a larger mascot, the five-hour and weekly remaining percentages, reset times, last-refresh state, a refresh action, and Quit.
- Remaining quota is the default semantic. Healthy, caution, and critical states use restrained mint, amber, and coral accents in the popover while the menu-bar drawing remains legible in both system appearances.
- Loading, signed-out, stale, and unavailable states show honest labels instead of invented percentages.

## Architecture

The project is a dependency-free Swift Package split into a reusable `CodexMochiCore` library and a native AppKit executable. The core owns credential discovery, JSON parsing, network access, quota state, and refresh timing. The app target owns the `NSStatusItem`, vector mascot drawing, popover, and user actions.

The app reads `CODEX_HOME/auth.json` when `CODEX_HOME` is set, otherwise `~/.codex/auth.json`. It uses the existing Codex access token only for `https://chatgpt.com/backend-api/wham/usage`, adds the Codex product headers, never persists the token, and limits response size. The response parser accepts the known ratio/percentage field variants and clamps values to 0...100.

## Data flow

1. Launch as an accessory application and immediately show a loading mascot.
2. Load the local Codex credential and request the usage endpoint off the main thread.
3. Parse the five-hour and weekly windows into immutable snapshot models.
4. Publish the snapshot on the main actor to update the status item and popover.
5. Refresh every 60 seconds and on demand. Preserve the last successful snapshot if a later request fails, while marking it stale.

## Error and privacy boundaries

- Missing or malformed auth becomes a signed-out state with a short recovery hint.
- Authentication failures, rate limits, network failures, oversized responses, and changed JSON schemas remain distinct errors.
- The app does not log tokens, account IDs, raw responses, prompts, or chat history.
- The app does not redeem reset credits or modify Codex account state.

## Testing and acceptance

- Unit tests cover percentage normalization, alternate response shapes, reset timestamps, clamping, state thresholds, and JWT account-ID extraction.
- `swift test` must pass.
- A release executable must build, and `scripts/build_app.sh` must produce `dist/CodexMochi.app` with `LSUIElement=true`.
- A smoke launch must create a running `CodexMochi` process without an immediate crash; the process is terminated after verification.

## First-version exclusions

No multi-provider support, historical charts, notifications, Mac App Store signing, auto-update, custom mascot store, or credential import UI.
