// Composes an App Store screenshot: a captured window on a branded background with a headline.
//
//   swift scripts/compose-screenshot.swift <input.png> <output.png> "Title" "Subtitle"
//
// Output is 2560×1600, one of the sizes App Store Connect accepts for macOS.
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 5 || arguments.count == 6 else {
    FileHandle.standardError.write(Data("usage: compose-screenshot.swift <input.png> <output.png> <title> <subtitle> [canvasWidth]\n".utf8))
    exit(1)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
let title = arguments[3]
let subtitle = arguments[4]

guard let shot = NSImage(contentsOf: inputURL) else {
    FileHandle.standardError.write(Data("error: couldn't read \(inputURL.path)\n".utf8))
    exit(1)
}

// App Store Connect accepts 2560×1600 and 1280×800 for macOS; smaller keeps captures sharp.
let canvasWidth = arguments.count == 6 ? (Double(arguments[5]) ?? 2560) : 2560
let canvas = NSSize(width: canvasWidth, height: (canvasWidth * 0.625).rounded())
let ratio = canvasWidth / 2560

let composed = NSImage(size: canvas, flipped: false) { rect in
    NSGradient(
        starting: NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.86, alpha: 1),
        ending: NSColor(calibratedRed: 0.05, green: 0.16, blue: 0.42, alpha: 1)
    )?.draw(in: rect, angle: -90)

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 104 * ratio, weight: .bold),
        .foregroundColor: NSColor.white,
    ]
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 50 * ratio, weight: .regular),
        .foregroundColor: NSColor.white.withAlphaComponent(0.82),
    ]
    let titleSize = title.size(withAttributes: titleAttributes)
    let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
    title.draw(
        at: NSPoint(x: (canvas.width - titleSize.width) / 2, y: canvas.height - 215 * ratio),
        withAttributes: titleAttributes
    )
    subtitle.draw(
        at: NSPoint(x: (canvas.width - subtitleSize.width) / 2, y: canvas.height - 305 * ratio),
        withAttributes: subtitleAttributes
    )

    // Fit the capture into the space below the headline, never upscaling past 2x.
    let available = NSSize(width: canvas.width - 560 * ratio, height: canvas.height - 540 * ratio)
    let scale = min(available.width / shot.size.width, available.height / shot.size.height, 2)
    let drawn = NSSize(width: shot.size.width * scale, height: shot.size.height * scale)
    let frame = NSRect(
        x: (canvas.width - drawn.width) / 2,
        y: (canvas.height - drawn.height) / 2 - 100 * ratio,
        width: drawn.width,
        height: drawn.height
    )

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
    shadow.shadowBlurRadius = 70
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    shot.draw(in: frame)
    NSGraphicsContext.current?.restoreGraphicsState()
    return true
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width),
    pixelsHigh: Int(canvas.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
composed.draw(in: NSRect(origin: .zero, size: canvas))
NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: couldn't encode PNG\n".utf8))
    exit(1)
}
try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try data.write(to: outputURL)
print("wrote \(outputURL.path) (\(Int(canvas.width))×\(Int(canvas.height)))")
