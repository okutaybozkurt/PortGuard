import SwiftUI

/// "Guard": PortGuard's minimal shield character. The body is the brand `PortGuardMark` silhouette
/// with a subtle blue-to-indigo gradient and two softly glowing capsule eyes. Expression comes only
/// from the eyes and a thin halo. Drawn in one `Canvas`; animation is driven by `TimelineView`
/// (<= 15 fps, paused while the window is inactive or the view is off-screen). With Reduce Motion
/// a single static frame is drawn.
public struct GuardMascot: View {
    public var mood: GuardMood
    public var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isOnScreen = true

    public init(mood: GuardMood = .idle, size: CGFloat = 40) {
        self.mood = mood
        self.size = size
    }

    private var interval: Double {
        (mood == .scanning || mood == .alert) ? 1.0 / 15.0 : 1.0 / 12.0
    }

    public var body: some View {
        Group {
            if reduceMotion {
                GuardMascotCanvas(mood: mood, t: 0.5)
            } else {
                TimelineView(.animation(minimumInterval: interval, paused: !isOnScreen || scenePhase != .active)) { timeline in
                    GuardMascotCanvas(mood: mood, t: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .accessibilityHidden(true)
    }
}

private struct GuardMascotCanvas: View {
    let mood: GuardMood
    let t: Double

    var body: some View {
        Canvas { context, canvasSize in
            var ctx = context
            GuardMascotRenderer.draw(&ctx, canvasSize, mood: mood, t: t)
        }
    }
}

private enum GuardMascotRenderer {
    static let top = Color(red: 0.33, green: 0.58, blue: 1.0)
    static let bottom = Color(red: 0.33, green: 0.28, blue: 0.82)
    static let eyeCool = Color(red: 0.85, green: 0.95, blue: 1.0)
    static let eyeGlowCool = Color(red: 0.45, green: 0.75, blue: 1.0)
    static let eyeWarm = Color(red: 1.0, green: 0.62, blue: 0.30)
    static let eyeGlowWarm = Color(red: 1.0, green: 0.30, blue: 0.20)

    static func draw(_ ctx: inout GraphicsContext, _ sz: CGSize, mood: GuardMood, t: Double) {
        let s = min(sz.width, sz.height)
        guard s > 0 else { return }
        let center = CGPoint(x: s / 2, y: s / 2)

        // Shield rect: PortGuardMark spans ~0.49 x 0.60 of its rect, centered at (0.5, 0.511).
        let k: CGFloat = 1.3
        let ks = k * s
        let shieldRect = CGRect(x: 0.5 * s - ks / 2, y: 0.5 * s - 0.511 * ks, width: ks, height: ks)
        let shield = PortGuardMark().path(in: shieldRect)

        // Breathing (idle / calm only).
        var breath = 1.0
        switch mood {
        case .idle:  breath = 1 + 0.012 * sin(t * 1.2)
        case .calm:  breath = 1 + 0.018 * sin(t * 0.8)
        default:     break
        }

        // Alert halo: thin ring expanding from the shield outline.
        if mood == .alert {
            let p = t * 0.9 - floor(t * 0.9)
            let scale = 1 + 0.22 * CGFloat(p)
            let ring = shield.applying(
                CGAffineTransform(translationX: -center.x, y: -center.y)
                    .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                    .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
            )
            ctx.stroke(ring, with: .color(eyeGlowWarm.opacity(0.55 * (1 - p))),
                       lineWidth: max(s * 0.02, 0.8))
        }

        // Body.
        ctx.translateBy(x: center.x, y: center.y)
        ctx.scaleBy(x: CGFloat(breath), y: CGFloat(breath))
        ctx.translateBy(x: -center.x, y: -center.y)

        ctx.fill(shield, with: .linearGradient(Gradient(colors: [top, bottom]),
                                               startPoint: CGPoint(x: s / 2, y: 0.1 * s),
                                               endPoint: CGPoint(x: s / 2, y: 0.92 * s)))
        ctx.stroke(shield, with: .color(.white.opacity(0.22)), lineWidth: max(s * 0.012, 0.5))

        // Eyes.
        let warm = mood == .alert
        let core = warm ? eyeWarm : eyeCool
        let glow = warm ? eyeGlowWarm : eyeGlowCool
        let eyeY = 0.45 * s
        let spacing = 0.125 * s

        var open = 1.0
        var shift = 0.0
        switch mood {
        case .idle:
            let ph = t.truncatingRemainder(dividingBy: 5.0)
            if ph < 0.14 { open = 1 - sin(ph / 0.14 * Double.pi) * 0.92 }
        case .scanning:
            shift = sin(t * 2.4) * 0.04 * Double(s)
        case .alert:
            open = 1.0
        case .calm:
            open = 0.14
        }

        let ew = 0.095 * s
        let eh = 0.17 * s * CGFloat(max(open, 0.12))
        for side in [-1.0, 1.0] {
            let cx = 0.5 * s + CGFloat(side) * spacing + CGFloat(shift)
            let rect = CGRect(x: cx - ew / 2, y: eyeY - eh / 2, width: ew, height: eh)
            let r = min(ew, eh) / 2
            // soft glow
            let g = rect.insetBy(dx: -0.025 * s, dy: -0.025 * s)
            ctx.fill(Path(roundedRect: g, cornerRadius: min(g.width, g.height) / 2),
                     with: .color(glow.opacity(mood == .calm ? 0.12 : 0.28)))
            ctx.fill(Path(roundedRect: rect, cornerRadius: r), with: .color(core))
        }
    }
}
