// Draws the ChromeSwitch app icon as an .iconset folder (run via `make icon`).
// A rounded square with a toggle switch: the whole point of the app in one glyph.
import AppKit

let outDir = CommandLine.arguments.dropFirst().first ?? "AppIcon.iconset"
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func draw(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let s = size / 1024
    // macOS icon shape: rounded square inset from the canvas edge.
    let inset = 100 * s
    let shape = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset),
                             xRadius: 185 * s, yRadius: 185 * s)
    let gradient = NSGradient(colors: [NSColor(calibratedRed: 0.13, green: 0.47, blue: 0.95, alpha: 1),
                                       NSColor(calibratedRed: 0.09, green: 0.25, blue: 0.62, alpha: 1)])!
    gradient.draw(in: shape, angle: -90)

    // Toggle track.
    let trackH = 260 * s, trackW = 520 * s
    let track = NSRect(x: (size - trackW) / 2, y: (size - trackH) / 2, width: trackW, height: trackH)
    NSColor(calibratedWhite: 1, alpha: 0.28).setFill()
    NSBezierPath(roundedRect: track, xRadius: trackH / 2, yRadius: trackH / 2).fill()

    // Knob, pushed to the right ("switched on").
    let knobD = trackH - 40 * s
    let knob = NSRect(x: track.maxX - knobD - 20 * s, y: track.minY + 20 * s, width: knobD, height: knobD)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: knob).fill()
    return image
}

func writePNG(_ image: NSImage, to path: String) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "make-icon", code: 1)
    }
    try png.write(to: URL(fileURLWithPath: path))
}

for base in [16, 32, 128, 256, 512] {
    try writePNG(draw(size: CGFloat(base)), to: "\(outDir)/icon_\(base)x\(base).png")
    try writePNG(draw(size: CGFloat(base * 2)), to: "\(outDir)/icon_\(base)x\(base)@2x.png")
}
print("Wrote iconset to \(outDir)")
