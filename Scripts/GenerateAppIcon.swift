import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconDirectory = root.appendingPathComponent("Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconDirectory, withIntermediateDirectories: true)
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let bounds = NSRect(x: 0, y: 0, width: size, height: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.12, alpha: 1),
    NSColor(calibratedRed: 0.30, green: 0.13, blue: 0.09, alpha: 1)
])!
gradient.draw(in: bounds, angle: 135)
let halo = NSBezierPath(ovalIn: NSRect(x: 90, y: 130, width: 844, height: 760))
NSColor(calibratedRed: 0.92, green: 0.31, blue: 0.13, alpha: 0.18).setFill()
halo.fill()
let road = NSBezierPath()
road.move(to: NSPoint(x: 0, y: 145))
road.curve(to: NSPoint(x: 1024, y: 215), controlPoint1: NSPoint(x: 280, y: 290), controlPoint2: NSPoint(x: 730, y: 65))
road.line(to: NSPoint(x: 1024, y: 0))
road.line(to: NSPoint(x: 0, y: 0))
road.close()
NSColor(calibratedRed: 0.035, green: 0.04, blue: 0.045, alpha: 1).setFill()
road.fill()
let stripe = NSBezierPath()
stripe.move(to: NSPoint(x: 0, y: 88))
stripe.line(to: NSPoint(x: 1024, y: 160))
stripe.lineWidth = 12
stripe.setLineDash([42, 34], count: 2, phase: 0)
NSColor(calibratedRed: 0.95, green: 0.62, blue: 0.27, alpha: 0.9).setStroke()
stripe.stroke()
let body = NSBezierPath()
body.move(to: NSPoint(x: 190, y: 390))
body.line(to: NSPoint(x: 250, y: 535))
body.curve(to: NSPoint(x: 405, y: 645), controlPoint1: NSPoint(x: 275, y: 650), controlPoint2: NSPoint(x: 350, y: 650))
body.line(to: NSPoint(x: 740, y: 645))
body.curve(to: NSPoint(x: 850, y: 520), controlPoint1: NSPoint(x: 820, y: 650), controlPoint2: NSPoint(x: 835, y: 575))
body.line(to: NSPoint(x: 900, y: 390))
body.close()
NSColor(calibratedRed: 0.70, green: 0.25, blue: 0.13, alpha: 1).setFill()
body.fill()
NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.045, alpha: 1).setStroke()
body.lineWidth = 24
body.stroke()
let glass = NSBezierPath(roundedRect: NSRect(x: 395, y: 540, width: 290, height: 95), xRadius: 22, yRadius: 22)
NSColor(calibratedRed: 0.10, green: 0.19, blue: 0.23, alpha: 1).setFill()
glass.fill()
let tireColor = NSColor(calibratedWhite: 0.035, alpha: 1)
for x: CGFloat in [290, 710] {
    let tire = NSBezierPath(ovalIn: NSRect(x: x-65, y: 310, width: 130, height: 130))
    tireColor.setFill()
    tire.fill()
    NSColor(calibratedWhite: 0.52, alpha: 1).setStroke()
    tire.lineWidth = 14
    tire.stroke()
    let hub = NSBezierPath(ovalIn: NSRect(x: x-20, y: 355, width: 40, height: 40))
    NSColor(calibratedRed: 0.78, green: 0.75, blue: 0.68, alpha: 1).setFill()
    hub.fill()
}
let light = NSBezierPath(roundedRect: NSRect(x: 850, y: 435, width: 48, height: 38), xRadius: 10, yRadius: 10)
NSColor(calibratedRed: 1, green: 0.78, blue: 0.38, alpha: 1).setFill()
light.fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to render DEAD MILE app icon")
}
try png.write(to: iconDirectory.appendingPathComponent("AppIcon.png"))
let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try contents.write(to: iconDirectory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Generated Assets.xcassets/AppIcon.appiconset/AppIcon.png")
