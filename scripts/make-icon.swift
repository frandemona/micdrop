import AppKit

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
    let disc = NSBezierPath(ovalIn: rect.insetBy(dx: 90, dy: 90))
    NSGradient(
        starting: NSColor(calibratedRed: 0.36, green: 0.66, blue: 1.0, alpha: 1),
        ending: NSColor(calibratedRed: 0.08, green: 0.34, blue: 0.86, alpha: 1)
    )!.draw(in: disc, angle: -90)

    NSColor.white.setStroke()
    let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 150, dy: 150))
    ring.lineWidth = 28
    ring.stroke()

    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 422, y: 480, width: 180, height: 300), xRadius: 90, yRadius: 90).fill()

    let holder = NSBezierPath()
    holder.lineWidth = 40
    holder.lineCapStyle = .round
    holder.move(to: NSPoint(x: 342, y: 640))
    holder.line(to: NSPoint(x: 342, y: 600))
    holder.appendArc(withCenter: NSPoint(x: 512, y: 600), radius: 170, startAngle: 180, endAngle: 360, clockwise: false)
    holder.line(to: NSPoint(x: 682, y: 640))
    holder.move(to: NSPoint(x: 512, y: 430))
    holder.line(to: NSPoint(x: 512, y: 340))
    holder.move(to: NSPoint(x: 412, y: 330))
    holder.line(to: NSPoint(x: 612, y: 330))
    holder.stroke()

    let slashGap = NSBezierPath()
    slashGap.lineWidth = 96
    slashGap.lineCapStyle = .round
    slashGap.move(to: NSPoint(x: 330, y: 800))
    slashGap.line(to: NSPoint(x: 700, y: 290))
    NSColor(calibratedRed: 0.20, green: 0.50, blue: 0.94, alpha: 1).setStroke()
    slashGap.stroke()

    let slash = NSBezierPath()
    slash.lineWidth = 44
    slash.lineCapStyle = .round
    slash.move(to: NSPoint(x: 330, y: 800))
    slash.line(to: NSPoint(x: 700, y: 290))
    NSColor.white.setStroke()
    slash.stroke()
    return true
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(side), pixelsHigh: Int(side),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
