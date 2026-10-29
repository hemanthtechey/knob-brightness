#!/bin/bash
# Installs knob-brightness as a login agent.  Uninstall: ./install.sh --uninstall
set -euo pipefail

LABEL=local.knob-brightness
DIR="$HOME/Library/Application Support/knob-brightness"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SRC_URL=https://raw.githubusercontent.com/hemanthtechey/knob-brightness/main/knob.swift

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

if [ "${1:-}" = "--uninstall" ]; then
  rm -rf "$DIR" "$PLIST"
  echo "Removed. Also remove 'knob-brightness' from System Settings → Privacy & Security → Accessibility."
  exit 0
fi

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "Install the Command Line Tools from the dialog, then run this again."
  exit 1
fi

mkdir -p "$DIR" "$HOME/Library/LaunchAgents"
# Works from a clone (uses the local file) or via curl | bash (downloads it).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -f "$HERE/knob.swift" ]; then cp "$HERE/knob.swift" "$DIR/"; else curl -fsSL "$SRC_URL" -o "$DIR/knob.swift"; fi

echo "Building…"
swiftc -O "$DIR/knob.swift" -o "$DIR/knob-brightness"
"$DIR/knob-brightness" --selftest

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$DIR/knob-brightness</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/knob-brightness.log</string>
  <key>StandardErrorPath</key><string>/tmp/knob-brightness.log</string>
</dict></plist>
EOF
launchctl bootstrap "gui/$(id -u)" "$PLIST"

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
echo "Installed. Last step: turn on 'knob-brightness' in the Accessibility list that just opened."
echo "Then hold Ctrl and turn your volume knob."
