// Renders the 1024 px app icon: a dark tile with a ring that runs from teal to red.
// swift tools/make_icon.swift Callout/Assets.xcassets/AppIcon.appiconset/icon.png
import AppKit

let size = 1024.0
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let center = NSPoint(x: size / 2, y: size / 2)
let radius = 330.0
let track = NSBezierPath()
track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
track.lineWidth = 90
NSColor(white: 1, alpha: 0.08).setStroke()
track.stroke()

// Ring arcs clockwise from 12 o'clock, cooling teal into hot red, leaving the last quarter empty.
let stops: [NSColor] = [
    NSColor(red: 0.25, green: 0.85, blue: 0.70, alpha: 1),
    NSColor(red: 1.0, green: 0.78, blue: 0.25, alpha: 1),
    NSColor(red: 1.0, green: 0.52, blue: 0.20, alpha: 1),
    NSColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1),
]
let segments = 120
let sweep = 270.0
for i in 0..<segments {
    let t = Double(i) / Double(segments - 1)
    let pos = t * Double(stops.count - 1)
    let a = stops[min(Int(pos), stops.count - 1)], b = stops[min(Int(pos) + 1, stops.count - 1)]
    let f = pos - Double(Int(pos))
    let color = a.blended(withFraction: f, of: b)!
    let start = 90 - sweep * Double(i) / Double(segments)
    let end = 90 - sweep * Double(i + 1) / Double(segments) - 0.6
    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    arc.lineWidth = 90
    arc.lineCapStyle = (i == 0 || i == segments - 1) ? .round : .butt
    color.setStroke()
    arc.stroke()
}

let text = "5" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 380, weight: .heavy),
    .foregroundColor: NSColor.white,
]
let textSize = text.size(withAttributes: attrs)
text.draw(at: NSPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2), withAttributes: attrs)

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
