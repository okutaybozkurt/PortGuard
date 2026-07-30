import SwiftUI
import AppKit

/// PortGuard's brand shield silhouette, matching the app icon's proportions.
/// Used in the menu bar and window headers in place of the generic "shield.tcp.fill" SF Symbol
/// so the tiny menu bar glyph, popover header, and dashboard header all share one consistent mark.
public struct PortGuardMark: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        func pt(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + fx * rect.width, y: rect.minY + fy * rect.height)
        }

        var path = Path()
        path.move(to: pt(0.5, 0.209))
        path.addCurve(to: pt(0.746, 0.275), control1: pt(0.588, 0.209), control2: pt(0.668, 0.234))
        path.addLine(to: pt(0.746, 0.467))
        path.addCurve(to: pt(0.5, 0.813), control1: pt(0.746, 0.637), control2: pt(0.645, 0.756))
        path.addCurve(to: pt(0.254, 0.467), control1: pt(0.355, 0.756), control2: pt(0.254, 0.637))
        path.addLine(to: pt(0.254, 0.275))
        path.addCurve(to: pt(0.5, 0.209), control1: pt(0.332, 0.234), control2: pt(0.412, 0.209))
        path.closeSubpath()
        return path
    }
}

public extension NSImage {
    /// Renders the PortGuard shield mark as a genuine template NSImage, drawn directly via
    /// NSBezierPath. The actual macOS menu bar (NSStatusItem) does not reliably render
    /// arbitrary SwiftUI `Shape` content — it needs a real template image — so the menu bar
    /// label uses this instead of `PortGuardMarkIcon`.
    static func portGuardMenuBarMark(pointSize: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: true) { rect in
            func pt(_ fx: CGFloat, _ fy: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + fx * rect.width, y: rect.minY + fy * rect.height)
            }

            let path = NSBezierPath()
            path.move(to: pt(0.5, 0.209))
            path.curve(to: pt(0.746, 0.275), controlPoint1: pt(0.588, 0.209), controlPoint2: pt(0.668, 0.234))
            path.line(to: pt(0.746, 0.467))
            path.curve(to: pt(0.5, 0.813), controlPoint1: pt(0.746, 0.637), controlPoint2: pt(0.645, 0.756))
            path.curve(to: pt(0.254, 0.467), controlPoint1: pt(0.355, 0.756), controlPoint2: pt(0.254, 0.637))
            path.line(to: pt(0.254, 0.275))
            path.curve(to: pt(0.5, 0.209), controlPoint1: pt(0.332, 0.234), controlPoint2: pt(0.412, 0.209))
            path.close()

            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}

public struct PortGuardMarkIcon: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 18, color: Color = .primary) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        PortGuardMark()
            .fill(color)
            .frame(width: size, height: size)
    }
}
