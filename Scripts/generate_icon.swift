#!/usr/bin/env swift

import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Flip coordinate system so y=0 is at top (easier to reason about)
    ctx.translateBy(x: 0, y: size)
    ctx.scaleBy(x: 1, y: -1)

    let padding = size * 0.12
    let winX = padding
    let winY = padding
    let winW = size - 2 * padding
    let winH = size - 2 * padding
    let cr = size * 0.07  // corner radius

    // --- Shadow ---
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: size * 0.02), blur: size * 0.06,
                  color: CGColor(gray: 0, alpha: 0.35))
    let windowPath = CGPath(roundedRect: CGRect(x: winX, y: winY, width: winW, height: winH),
                            cornerWidth: cr, cornerHeight: cr, transform: nil)
    ctx.addPath(windowPath)
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // --- Clip to window shape for all subsequent drawing ---
    ctx.saveGState()
    ctx.addPath(windowPath)
    ctx.clip()

    // --- Window body (white) ---
    ctx.setFillColor(CGColor(gray: 0.98, alpha: 1))
    ctx.fill(CGRect(x: winX, y: winY, width: winW, height: winH))

    // --- Title bar ---
    let tbH = size * 0.14
    let tbRect = CGRect(x: winX, y: winY, width: winW, height: tbH)
    ctx.setFillColor(CGColor(gray: 0.90, alpha: 1))
    ctx.fill(tbRect)

    // Title bar separator
    ctx.setStrokeColor(CGColor(gray: 0.80, alpha: 1))
    ctx.setLineWidth(max(0.5, size * 0.004))
    ctx.move(to: CGPoint(x: winX, y: winY + tbH))
    ctx.addLine(to: CGPoint(x: winX + winW, y: winY + tbH))
    ctx.strokePath()

    // --- Traffic lights ---
    let dotR = size * 0.02
    let dotCY = winY + tbH / 2
    let dotStartX = winX + size * 0.065
    let dotSpacing = size * 0.048

    let dotColors: [(CGFloat, CGFloat, CGFloat)] = [
        (1.0, 0.38, 0.35),   // close (red)
        (1.0, 0.78, 0.24),   // minimize (yellow)
        (0.30, 0.85, 0.39),  // zoom (green)
    ]
    for (i, rgb) in dotColors.enumerated() {
        let cx = dotStartX + CGFloat(i) * dotSpacing
        ctx.setFillColor(CGColor(srgbRed: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1))
        ctx.fillEllipse(in: CGRect(x: cx - dotR, y: dotCY - dotR, width: dotR * 2, height: dotR * 2))
    }

    ctx.restoreGState() // end clip

    // --- Resize arrows centered in window body ---
    let bodyTop = winY + tbH
    let bodyCX = winX + winW / 2
    let bodyCY = bodyTop + (winH - tbH) / 2

    let arrowLen = size * 0.19
    let headLen = size * 0.065
    let lw = max(1.5, size * 0.028)
    let gap = size * 0.035

    // macOS accent blue
    ctx.setStrokeColor(CGColor(srgbRed: 0.20, green: 0.45, blue: 1.0, alpha: 1.0))
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(lw)

    let diag: CGFloat = 1 / sqrt(2)

    // Arrow 1: upper-left
    let a1sx = bodyCX - gap * diag
    let a1sy = bodyCY - gap * diag
    let a1ex = bodyCX - arrowLen * diag
    let a1ey = bodyCY - arrowLen * diag

    ctx.move(to: CGPoint(x: a1sx, y: a1sy))
    ctx.addLine(to: CGPoint(x: a1ex, y: a1ey))
    // arrowhead
    ctx.move(to: CGPoint(x: a1ex + headLen, y: a1ey))
    ctx.addLine(to: CGPoint(x: a1ex, y: a1ey))
    ctx.addLine(to: CGPoint(x: a1ex, y: a1ey + headLen))
    ctx.strokePath()

    // Arrow 2: lower-right
    let a2sx = bodyCX + gap * diag
    let a2sy = bodyCY + gap * diag
    let a2ex = bodyCX + arrowLen * diag
    let a2ey = bodyCY + arrowLen * diag

    ctx.move(to: CGPoint(x: a2sx, y: a2sy))
    ctx.addLine(to: CGPoint(x: a2ex, y: a2ey))
    // arrowhead
    ctx.move(to: CGPoint(x: a2ex - headLen, y: a2ey))
    ctx.addLine(to: CGPoint(x: a2ex, y: a2ey))
    ctx.addLine(to: CGPoint(x: a2ex, y: a2ey - headLen))
    ctx.strokePath()

    // --- Window border ---
    ctx.addPath(windowPath)
    ctx.setStrokeColor(CGColor(gray: 0.75, alpha: 1))
    ctx.setLineWidth(max(0.5, size * 0.004))
    ctx.strokePath()

    image.unlockFocus()
    return image
}

// --- Generate iconset ---
let iconsetPath = "/tmp/Holdfast.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let img = drawIcon(size: size)
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to render \(name)\n", stderr)
        continue
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

print("Iconset written to \(iconsetPath)")
