// Knob-brightness: Ctrl + volume knob (or any volume key) changes screen brightness instead.
// The EvoFox Ronin TKL never reports Fn to the Mac, so Ctrl is the modifier.
import AppKit

// NX_KEYTYPE_* media key codes from IOKit/hidsystem/ev_keymap.h
let soundUp = 0, soundDown = 1, brightnessUp = 2, brightnessDown = 3

/// Brightness key to send instead, or nil to let the event through untouched.
func remap(_ key: Int, ctrl: Bool) -> Int? {
    guard ctrl else { return nil }
    return key == soundUp ? brightnessUp : key == soundDown ? brightnessDown : nil
}

if CommandLine.arguments.contains("--selftest") {
    precondition(remap(soundUp, ctrl: true) == brightnessUp)
    precondition(remap(soundDown, ctrl: true) == brightnessDown)
    precondition(remap(soundUp, ctrl: false) == nil)
    precondition(remap(7, ctrl: true) == nil)  // mute (knob press) stays mute
    print("selftest ok"); exit(0)
}

func post(_ key: Int, down: Bool) {
    let data1 = (key << 16) | ((down ? 0xA : 0xB) << 8)
    NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: NSEvent.ModifierFlags(rawValue: down ? 0xA00 : 0xB00),
                       timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: data1, data2: -1)?
        .cgEvent?.post(tap: .cghidEventTap)
}

var tap: CFMachPort?
let callback: CGEventTapCallBack = { _, type, event, _ in
    // macOS switches the tap off if it is slow or the user interrupts it; switch it back on.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    guard let ns = NSEvent(cgEvent: event), ns.subtype.rawValue == 8 else { return Unmanaged.passUnretained(event) }
    let key = (ns.data1 & 0xFFFF0000) >> 16, down = (ns.data1 & 0xFF00) >> 8 == 0xA
    let ctrl = CGEventSource.flagsState(.combinedSessionState).contains(.maskControl)
    guard let to = remap(key, ctrl: ctrl) else { return Unmanaged.passUnretained(event) }
    if down { post(to, down: true); post(to, down: false) }
    return nil  // swallow the volume event (both down and up)
}

let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
if !AXIsProcessTrustedWithOptions(opts) {
    print("Grant Accessibility access to this binary in System Settings → Privacy & Security → Accessibility")
}
// NX_SYSDEFINED (14) carries media keys; it has no CGEventType case, hence the raw mask.
while true {
    tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                            eventsOfInterest: 1 << 14, callback: callback, userInfo: nil)
    if tap != nil { break }
    sleep(5)  // not trusted yet; retry until Accessibility is granted
}
CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
CGEvent.tapEnable(tap: tap!, enable: true)
print("knob-brightness running")
RunLoop.main.run()
