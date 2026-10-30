# knob-brightness

Hold **Ctrl** and turn your keyboard's volume knob to change your Mac's screen brightness.
A plain turn still changes volume, and pressing the knob still mutes.

Made for the **EvoFox Ronin TKL**, but it works with any keyboard's volume knob or volume keys.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hemanthtechey/knob-brightness/main/install.sh | bash
```

Then turn on **knob-brightness** in the Accessibility list that opens
(System Settings → Privacy & Security → Accessibility). That's it. It starts automatically at login.

If the Command Line Tools aren't installed yet, the script opens the installer for you. Run the command again once they're installed.

## Manual install (step by step)

Prefer to run each command yourself? Do this instead of the one-liner above.

```bash
# 1. Get the code
git clone https://github.com/hemanthtechey/knob-brightness.git
cd knob-brightness

# 2. Build it
mkdir -p ~/Library/Application\ Support/knob-brightness
swiftc -O knob.swift -o ~/Library/Application\ Support/knob-brightness/knob-brightness

# 3. Start it now and at every login
sed "s|__HOME__|$HOME|" local.knob-brightness.plist > ~/Library/LaunchAgents/local.knob-brightness.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.knob-brightness.plist
```

4. Go to **System Settings → Privacy & Security → Accessibility** and turn on **knob-brightness**.
5. Hold **Ctrl** and turn the knob.

If the brightness doesn't change, check the log at `/tmp/knob-brightness.log` and
[open an issue](https://github.com/hemanthtechey/knob-brightness/issues) with its contents.

Stop it: `launchctl bootout gui/$(id -u)/local.knob-brightness`

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/hemanthtechey/knob-brightness/main/install.sh | bash -s -- --uninstall
```

## Why not Fn + knob?

On the EvoFox Ronin TKL (USB `320F:5055`), the knob sends standard media codes from its firmware:
Volume Up `0xE9`, Volume Down `0xEA` and Mute `0xE2`.
**Holding Fn doesn't change what the knob sends, and Fn itself is never reported to the Mac.**
That means no Mac software can detect Fn + knob, so this tool uses Ctrl instead.

## How it works

`knob.swift` (~60 lines) listens for media-key events. When Ctrl is held, it swallows Volume Up/Down
and sends Brightness Up/Down instead. It needs Accessibility permission to change key events.
It's built from source on your Mac, so there's no prebuilt binary to trust.

## Notes

- It changes the brightness of the built-in display. External monitors usually ignore brightness keys.
- Ctrl + volume works on every keyboard you have connected, including the MacBook's own keys.
- Log: `/tmp/knob-brightness.log` · Self-test: `~/Library/Application\ Support/knob-brightness/knob-brightness --selftest`
- If you reinstall, macOS sees a new binary, so you may need to turn it on again in Accessibility.

## Licence

MIT, see [LICENSE](LICENSE).
