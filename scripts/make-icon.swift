// Renders Resources/AppIcon.svg into a 1024x1024 PNG with Apple's icon-grid margin.
// Usage: swift scripts/make-icon.swift <in.svg> <out.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let svg = NSImage(contentsOfFile: args[1]) else {
    fatalError("usage: make-icon.swift <in.svg> <out.png>")
}

let canvas = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvas,
    pixelsHigh: canvas,
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

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
// 824x824 body centred on the 1024 canvas, as in Apple's macOS icon template.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
svg.draw(in: body)
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("cannot encode PNG")
}
try png.write(to: URL(fileURLWithPath: args[2]))
