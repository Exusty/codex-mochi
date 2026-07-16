#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/CodexMochi.app"
CONTENTS="$APP/Contents"

swift build --package-path "$ROOT" -c release
BIN_DIR="$(swift build --package-path "$ROOT" -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
install -m 755 "$BIN_DIR/CodexMochi" "$CONTENTS/MacOS/CodexMochi"
install -m 644 "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$APP" >/dev/null
touch "$APP"

echo "Built $APP"
