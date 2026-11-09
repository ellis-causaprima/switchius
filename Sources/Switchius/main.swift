import AppKit

// No storyboard, no nib: build the app object by hand and hand it the delegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Menu bar only. Info.plist also sets LSUIElement; this covers running the bare binary.
app.setActivationPolicy(.accessory)
app.run()
