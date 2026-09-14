import AppKit

// Renders the .iconset PNGs for AppIcon.icns. Usage: swift make-app-icon.swift <output-dir>

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

func whiteSilhouette(of symbol: NSImage) -> NSImage {
    NSImage(size: symbol.size, flipped: false) { rect in
        NSColor.white.set()
        rect.fill()
        symbol.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
        return true
    }
}

func render(pixels: Int) -> Data? {
    let size = CGFloat(pixels)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = size * 0.055
    let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let squircle = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.2237, yRadius: tile.width * 0.2237)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.36, green: 0.39, blue: 0.45, alpha: 1),
        NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.15, alpha: 1),
    ])?.draw(in: squircle, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: tile.width * 0.46, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "square.stack", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let glyph = whiteSilhouette(of: symbol)
        let box = NSRect(
            x: tile.midX - glyph.size.width / 2,
            y: tile.midY - glyph.size.height / 2,
            width: glyph.size.width, height: glyph.size.height
        )
        glyph.draw(in: box)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("usage: make-app-icon.swift <output-dir>\n".utf8))
    exit(2)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for variant in variants {
    guard let png = render(pixels: variant.pixels) else {
        FileHandle.standardError.write(Data("failed: \(variant.name)\n".utf8))
        exit(1)
    }
    try png.write(to: outDir.appendingPathComponent("\(variant.name).png"))
}
print("wrote \(variants.count) PNGs to \(outDir.path)")
