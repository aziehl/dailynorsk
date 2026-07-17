#!/usr/bin/env swift

import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ??
    "NorskWordOfTheDay/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size = 1024
let background = NSColor(
    calibratedRed: 0.729,
    green: 0.047,
    blue: 0.184,
    alpha: 1
)

guard let font = NSFont(name: "Avenir Next Demi Bold", size: 248) else {
    fputs("Avenir Next Demi Bold is unavailable on this Mac.\n", stderr)
    exit(1)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Could not create an icon drawing context.\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
background.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.lineBreakMode = .byClipping
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .kern: 0,
    .paragraphStyle: paragraph,
]

for (text, y) in [("Daily", 518.0), ("norsk", 264.0)] {
    let line = NSAttributedString(string: text, attributes: attributes)
    line.draw(in: NSRect(x: 64, y: y, width: 896, height: 260))
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode the app icon as PNG.\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
