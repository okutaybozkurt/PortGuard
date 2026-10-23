import AppKit

/// Face variants of the Guard menu bar glyph.
public enum GuardMenuBarFace: Hashable {
    case normal   // eyes + smile
    case blink    // eyes as thin lines + smile
    case sleepy   // 0 active ports: eyes as lines, tiny smile
    case alert    // rule violation / conflict: big eyes + exclamation mark
}

public extension NSImage {
    /// Template menu bar image of Guard's face. The shield is the PortGuardMark silhouette scaled
    /// to fill the image; eyes/mouth are punched out with the even-odd rule, so it works as a true
    /// template image (no clear-compositing tricks needed). Images are cached per face and size.
    static func guardMenuBar(face: GuardMenuBarFace, pointSize: CGFloat = 18) -> NSImage {
        let key = GuardMenuBarCache.Key(face: face, size: pointSize)
        if let cached = GuardMenuBarCache.images[key] { return cached }

        let image = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: true) { rect in
            let w = rect.width, h = rect.height
            func pt(_ fx: CGFloat, _ fy: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + fx * w, y: rect.minY + fy * h)
            }
            // Shield silhouette (PortGuardMark coordinates), scaled up around its center.
            let k: CGFloat = 1.45
            func sp(_ fx: CGFloat, _ fy: CGFloat) -> NSPoint {
                pt(0.5 + (fx - 0.5) * k, 0.5 + (fy - 0.511) * k)
            }
            let path = NSBezierPath()
            path.windingRule = .evenOdd
            path.move(to: sp(0.5, 0.209))
            path.curve(to: sp(0.746, 0.275), controlPoint1: sp(0.588, 0.209), controlPoint2: sp(0.668, 0.234))
            path.line(to: sp(0.746, 0.467))
            path.curve(to: sp(0.5, 0.813), controlPoint1: sp(0.746, 0.637), controlPoint2: sp(0.645, 0.756))
            path.curve(to: sp(0.254, 0.467), controlPoint1: sp(0.355, 0.756), controlPoint2: sp(0.254, 0.637))
            path.line(to: sp(0.254, 0.275))
            path.curve(to: sp(0.5, 0.209), controlPoint1: sp(0.332, 0.234), controlPoint2: sp(0.412, 0.209))
            path.close()

            func oval(_ cx: CGFloat, _ cy: CGFloat, _ ew: CGFloat, _ eh: CGFloat) {
                let c = pt(cx, cy)
                path.append(NSBezierPath(ovalIn: NSRect(x: c.x - ew * w / 2, y: c.y - eh * h / 2, width: ew * w, height: eh * h)))
            }
            func bar(_ cx: CGFloat, _ cy: CGFloat, _ bw: CGFloat, _ bh: CGFloat) {
                let c = pt(cx, cy)
                let r = NSRect(x: c.x - bw * w / 2, y: c.y - bh * h / 2, width: bw * w, height: bh * h)
                path.append(NSBezierPath(roundedRect: r, xRadius: bh * h / 2, yRadius: bh * h / 2))
            }
            /// Crescent smile centered at (cx, cy), width sw, thickness th.
            func smile(_ cx: CGFloat, _ cy: CGFloat, _ sw: CGFloat, _ depth: CGFloat, _ th: CGFloat) {
                let s = NSBezierPath()
                s.move(to: pt(cx - sw / 2, cy))
                s.curve(to: pt(cx + sw / 2, cy),
                        controlPoint1: pt(cx - sw / 4, cy + depth),
                        controlPoint2: pt(cx + sw / 4, cy + depth))
                s.curve(to: pt(cx - sw / 2, cy),
                        controlPoint1: pt(cx + sw / 4, cy + depth - th),
                        controlPoint2: pt(cx - sw / 4, cy + depth - th))
                s.close()
                path.append(s)
            }

            switch face {
            case .normal:
                oval(0.35, 0.43, 0.15, 0.20)
                oval(0.65, 0.43, 0.15, 0.20)
                smile(0.5, 0.60, 0.26, 0.17, 0.08)
            case .blink:
                bar(0.35, 0.45, 0.16, 0.055)
                bar(0.65, 0.45, 0.16, 0.055)
                smile(0.5, 0.60, 0.26, 0.17, 0.08)
            case .sleepy:
                bar(0.35, 0.46, 0.17, 0.055)
                bar(0.65, 0.46, 0.17, 0.055)
                smile(0.5, 0.64, 0.14, 0.09, 0.06)
            case .alert:
                oval(0.34, 0.38, 0.19, 0.27)
                oval(0.66, 0.38, 0.19, 0.27)
                bar(0.5, 0.64, 0.085, 0.17)
                oval(0.5, 0.79, 0.095, 0.095)
            }

            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        GuardMenuBarCache.images[key] = image
        return image
    }
}

private enum GuardMenuBarCache {
    struct Key: Hashable {
        let face: GuardMenuBarFace
        let size: CGFloat
    }
    // Only touched from the main thread (SwiftUI view bodies).
    static var images: [Key: NSImage] = [:]
}
