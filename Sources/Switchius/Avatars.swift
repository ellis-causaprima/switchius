import AppKit
import SwitchiusCore

/// Round profile pictures for the menu and the menu bar, with an SF Symbol fallback.
enum Avatars {
    static func image(for profile: ChromeProfile, diameter: CGFloat) -> NSImage {
        if let url = ChromeProfileStore.pictureURL(for: profile), let picture = NSImage(contentsOf: url) {
            return circular(picture, diameter: diameter)
        }
        let fallback = NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: profile.name)!
        fallback.size = NSSize(width: diameter, height: diameter)
        return fallback
    }

    private static func circular(_ source: NSImage, diameter: CGFloat) -> NSImage {
        let size = NSSize(width: diameter, height: diameter)
        return NSImage(size: size, flipped: false) { rect in
            NSBezierPath(ovalIn: rect).addClip()
            source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
    }
}
