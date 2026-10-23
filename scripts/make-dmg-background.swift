// Draws the DMG window background: what to double-click and what to do if macOS blocks it.
// Usage: swift scripts/make-dmg-background.swift <out-dir>  → background.png, background@2x.png
// Layout must match Resources/dmg/settings.py (window 640x400, installer icon at x=320, y=210).
// Text sits at the top: on macOS 27 Finder adds a toolbar and status bar, which cut off the bottom of the window.
import AppKit

let width: CGFloat = 640
let height: CGFloat = 400
// Mid-tone, so Finder's icon labels (black in light mode, white in dark mode) stay readable.
let topColor = NSColor(srgbRed: 0x8a / 255, green: 0x8f / 255, blue: 0x9c / 255, alpha: 1)
let bottomColor = NSColor(srgbRed: 0x6c / 255, green: 0x71 / 255, blue: 0x7e / 255, alpha: 1)

func drawBackground() {
    let gradient = NSGradient(starting: topColor, ending: bottomColor)
    gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    drawCentered("Double-click “Install MCTweaks” to install", y: 340, font: .boldSystemFont(ofSize: 17))
    drawCentered("Blocked? Open System Settings → Privacy & Security", y: 306, font: .systemFont(ofSize: 13))
    drawCentered("and click “Open Anyway”. Then double-click the installer again.", y: 288, font: .systemFont(ofSize: 13))
}

func drawCentered(_ text: String, y: CGFloat, font: NSFont) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    shadow.shadowBlurRadius = 2
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: shadow,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let size = string.size()
    let point = NSPoint(x: (width - size.width) / 2, y: y)
    string.draw(at: point)
}

func render(scale: CGFloat, to path: String) throws {
    let pixelsWide = Int(width * scale)
    let pixelsHigh = Int(height * scale)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelsWide,
        pixelsHigh: pixelsHigh,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("cannot create bitmap")
    }
    // Point size stays 640x400; the pixel count gives the @2x density.
    bitmap.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawBackground()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("cannot encode PNG")
    }
    try png.write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
guard args.count == 2 else {
    fatalError("usage: make-dmg-background.swift <out-dir>")
}
try render(scale: 1, to: args[1] + "/background.png")
try render(scale: 2, to: args[1] + "/background@2x.png")
