#!/usr/bin/swift
import AppKit

let iconSize: CGFloat = 1024
let outputPath = "Sources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let image = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { _ in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    // Fond crème
    NSColor(red: 0.957, green: 0.941, blue: 0.910, alpha: 1.0).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: iconSize, height: iconSize)).fill()

    // Dimensions de la page (portrait, centrée, légèrement remontée)
    let marginH: CGFloat = 175
    let marginBottom: CGFloat = 145
    let marginTop: CGFloat = 90
    let pageRect = NSRect(
        x: marginH,
        y: marginBottom,
        width: iconSize - 2 * marginH,
        height: iconSize - marginTop - marginBottom
    )

    // Ombre portée
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 10, height: -16),
        blur: 32,
        color: NSColor.black.withAlphaComponent(0.20).cgColor
    )
    NSColor.white.setFill()
    NSBezierPath(roundedRect: pageRect, xRadius: 8, yRadius: 8).fill()
    ctx.restoreGState()

    // Page blanche (par-dessus l'ombre)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: pageRect, xRadius: 8, yRadius: 8).fill()

    // Curseur : fin trait noir vertical, haut-gauche de la page
    let cursorX = pageRect.minX + 112
    let cursorY = pageRect.maxY - 210
    let cursorRect = NSRect(x: cursorX, y: cursorY, width: 22, height: 160)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: cursorRect, xRadius: 2, yRadius: 2).fill()

    return true
}

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Erreur : impossible de créer le CGImage"); exit(1)
}

let rep = NSBitmapImageRep(cgImage: cgImage)
rep.size = NSSize(width: iconSize, height: iconSize)
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    print("Erreur : impossible de créer le PNG"); exit(1)
}

try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Icône générée : \(outputPath)")
