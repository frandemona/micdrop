// Fits a real screen capture to an App Store screenshot size, with no marketing furniture:
// crops to the target aspect ratio (centred) and scales. Apple guideline 2.3.3 wants screenshots
// that show the app in use, so these stay plain captures of the desktop with MicDrop on it.
//
//   swift scripts/fit-screenshot.swift <input.png> <output.png> [width] [height]
//
// Defaults to 2560x1600. Other accepted macOS sizes: 1280x800, 1440x900, 2880x1800.
import AppKit

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: fit-screenshot.swift <input.png> <output.png> [width] [height]\n".utf8))
    exit(1)
}
let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
let target = NSSize(
    width: arguments.count > 3 ? (Double(arguments[3]) ?? 2560) : 2560,
    height: arguments.count > 4 ? (Double(arguments[4]) ?? 1600) : 1600
)

guard let source = NSImage(contentsOf: inputURL),
      let sourceRep = NSImageRep(contentsOf: inputURL) else {
    FileHandle.standardError.write(Data("error: couldn't read \(inputURL.path)\n".utf8))
    exit(1)
}
// Work in real pixels, not points: a Retina capture reports half-size points.
let pixels = NSSize(width: sourceRep.pixelsWide, height: sourceRep.pixelsHigh)
source.size = pixels

// Crop to the target ratio, keeping the top of the frame (that's where the menu bar lives).
let targetRatio = target.width / target.height
let sourceRatio = pixels.width / pixels.height
var crop = NSRect(origin: .zero, size: pixels)
if sourceRatio > targetRatio {
    // Anchor right: MicDrop lives in the top-right of the menu bar, so trim from the left.
    crop.size.width = pixels.height * targetRatio
    crop.origin.x = pixels.width - crop.size.width
} else if sourceRatio < targetRatio {
    crop.size.height = pixels.width / targetRatio
    crop.origin.y = pixels.height - crop.size.height
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(target.width),
    pixelsHigh: Int(target.height),
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
NSGraphicsContext.current?.imageInterpolation = .high
source.draw(
    in: NSRect(origin: .zero, size: target),
    from: crop,
    operation: .copy,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: couldn't encode PNG\n".utf8))
    exit(1)
}
try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try data.write(to: outputURL)
print("wrote \(outputURL.path) (\(Int(target.width))x\(Int(target.height))) from \(Int(pixels.width))x\(Int(pixels.height))")
