import SwiftUI

/// "Guard": PortGuard's shield mascot. The body is the brand `PortGuardMark` silhouette, scaled up
/// and given a face, tiny arms and an antenna. Everything is drawn in a single `Canvas`
/// (no image assets). Animation is time-driven via `TimelineView`; with Reduce Motion enabled
/// a single static frame is drawn instead.
public struct GuardMascot: View {
    public var mood: GuardMood
    public var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = true

    public init(mood: GuardMood = .idle, size: CGFloat = 28) {
        self.mood = mood
        self.size = size
    }

    public var body: some View {
        Group {
            if reduceMotion {
                GuardMascotCanvas(mood: mood, t: 0)
            } else {
                TimelineView(.animation(minimumInterval: (mood == .idle || mood == .sleepy) ? 1.0 / 14.0 : 1.0 / 30.0, paused: !isVisible)) { timeline in
                    GuardMascotCanvas(mood: mood, t: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
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
    static let navy = Color(red: 0.07, green: 0.12, blue: 0.30)
    static let skyTop = Color(red: 0.42, green: 0.74, blue: 1.0)
    static let skyBottom = Color(red: 0.10, green: 0.32, blue: 0.88)
    static let handColor = Color(red: 0.62, green: 0.82, blue: 1.0)
    static let armColor = Color(red: 0.16, green: 0.42, blue: 0.92)
    static let cheek = Color(red: 1.0, green: 0.52, blue: 0.68)

    static func frac(_ x: Double) -> Double { x - floor(x) }

    static func draw(_ ctx: inout GraphicsContext, _ sz: CGSize, mood: GuardMood, t: Double) {
        let s = min(sz.width, sz.height)
        guard s > 0 else { return }
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: CGFloat(x) * s, y: CGFloat(y) * s) }
        let lw = max(s * 0.022, 1.0)

        // MARK: motion parameters
        var dy = 0.0
        var rotDeg = 0.0
        var breath = 1.0
        switch mood {
        case .idle:
            dy = sin(t * 1.6) * 0.012
            breath = 1 + 0.015 * sin(t * 2.2)
        case .happy:
            dy = -abs(sin(t * 5)) * 0.07
        case .celebrating:
            dy = -abs(sin(t * 6)) * 0.09
        case .alert:
            rotDeg = sin(t * 28) * 3
        case .sleepy:
            dy = 0.01 * sin(t * 1.1)
            breath = 1 + 0.025 * sin(t * 1.1)
        case .worried:
            rotDeg = sin(t * 9) * 1.2
        }

        let ph = t.truncatingRemainder(dividingBy: 4.2)
        let blink = ph < 0.16 ? sin(ph / 0.16 * Double.pi) : 0
        var eyeOpen = 1 - blink
        if mood == .sleepy { eyeOpen = 0 }

        // MARK: untransformed overlays (behind body): confetti
        if mood == .celebrating && s >= 30 {
            let colors: [Color] = [.yellow, .pink, .cyan, .orange, .green, .purple]
            for i in 0..<8 {
                let x = 0.05 + 0.9 * frac(Double(i) * 0.381966)
                let p = frac(t * 0.5 + Double(i) * 0.173)
                let y = p * 1.0
                let a = p * 6 + Double(i)
                var r = Path(CGRect(x: -0.02 * Double(s), y: -0.012 * Double(s), width: 0.04 * Double(s), height: 0.024 * Double(s)))
                r = r.applying(CGAffineTransform(rotationAngle: CGFloat(a)).concatenating(CGAffineTransform(translationX: CGFloat(x) * s, y: CGFloat(y) * s)))
                ctx.fill(r, with: .color(colors[i % colors.count].opacity(0.9)))
            }
        }

        // MARK: body transform
        ctx.translateBy(x: s * 0.05, y: s * 0.1)
        ctx.scaleBy(x: 0.9, y: 0.9)
        ctx.translateBy(x: 0, y: CGFloat(dy) * s)
        let pivot = P(0.5, 0.9)
        ctx.translateBy(x: pivot.x, y: pivot.y)
        ctx.rotate(by: .degrees(rotDeg))
        ctx.scaleBy(x: CGFloat(breath), y: CGFloat(breath))
        ctx.translateBy(x: -pivot.x, y: -pivot.y)

        // MARK: antenna (behind body)
        let sway = mood == .idle ? sin(t * 3) * 0.02 : 0
        let tip = P(0.5 + sway, 0.055)
        var antenna = Path()
        antenna.move(to: P(0.5, 0.16))
        antenna.addLine(to: tip)
        ctx.stroke(antenna, with: .color(armColor), style: StrokeStyle(lineWidth: max(s * 0.03, 1), lineCap: .round))
        let ballR = s * (mood == .alert ? 0.045 + 0.012 * CGFloat(abs(sin(t * 8))) : 0.04)
        let ballColor: Color = mood == .alert ? .red : (mood == .sleepy ? Color.gray : .orange)
        ctx.fill(Path(ellipseIn: CGRect(x: tip.x - ballR, y: tip.y - ballR, width: ballR * 2, height: ballR * 2)), with: .color(ballColor))
        if s >= 24 {
            let hr = ballR * 0.35
            ctx.fill(Path(ellipseIn: CGRect(x: tip.x - ballR * 0.45, y: tip.y - ballR * 0.5, width: hr, height: hr)), with: .color(.white.opacity(0.8)))
        }

        // MARK: arms (behind body)
        func arm(_ side: Double, hand: CGPoint) {
            var a = Path()
            a.move(to: P(0.5 + side * 0.2, 0.66))
            a.addLine(to: hand)
            ctx.stroke(a, with: .color(armColor), style: StrokeStyle(lineWidth: max(s * 0.05, 1.2), lineCap: .round))
            let hr = s * 0.055
            let hp = Path(ellipseIn: CGRect(x: hand.x - hr, y: hand.y - hr, width: hr * 2, height: hr * 2))
            ctx.fill(hp, with: .color(handColor))
            ctx.stroke(hp, with: .color(armColor.opacity(0.6)), lineWidth: max(s * 0.012, 0.6))
        }
        var leftHand = P(0.13, 0.64)
        var rightHand = P(0.87, 0.64)
        switch mood {
        case .happy:
            rightHand = P(0.9, 0.46 + sin(t * 8) * 0.04)
        case .celebrating:
            leftHand = P(0.1, 0.36 + sin(t * 9) * 0.04)
            rightHand = P(0.9, 0.36 + sin(t * 9 + 1) * 0.04)
        case .alert:
            leftHand = P(0.15, 0.44)
            rightHand = P(0.85, 0.44)
        case .worried:
            leftHand = P(0.26, 0.82)
            rightHand = P(0.74, 0.82)
        case .sleepy:
            leftHand = P(0.15, 0.72)
            rightHand = P(0.85, 0.72)
        case .idle:
            break
        }
        arm(-1, hand: leftHand)
        arm(1, hand: rightHand)

        // MARK: shield body (PortGuardMark silhouette, scaled up)
        let k = 1.4
        let ks = CGFloat(k) * s
        let bodyRect = CGRect(x: 0.5 * s - 0.5 * ks, y: 0.56 * s - 0.511 * ks, width: ks, height: ks)
        let body = PortGuardMark().path(in: bodyRect)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [skyTop, skyBottom]), startPoint: P(0.5, 0.14), endPoint: P(0.5, 0.99)))
        ctx.stroke(body, with: .color(.white.opacity(0.35)), lineWidth: max(s * 0.02, 0.6))
        // gloss
        ctx.fill(Path(ellipseIn: CGRect(x: 0.27 * s, y: 0.19 * s, width: 0.16 * s, height: 0.07 * s)), with: .color(.white.opacity(0.22)))

        // MARK: eyes
        let eyeY = 0.48
        let eyeScale: CGFloat = mood == .alert ? 1.25 : (mood == .worried ? 0.92 : 1.0)
        for side in [-1.0, 1.0] {
            let cx = 0.5 + side * 0.15
            let center = P(cx, eyeY)
            if mood == .celebrating {
                // ^ ^ eyes
                var p = Path()
                p.move(to: P(cx - 0.065, eyeY + 0.02))
                p.addQuadCurve(to: P(cx + 0.065, eyeY + 0.02), control: P(cx, eyeY - 0.08))
                ctx.stroke(p, with: .color(navy), style: StrokeStyle(lineWidth: lw * 1.3, lineCap: .round))
            } else if eyeOpen < 0.2 {
                // closed eye (sleepy or mid-blink)
                var p = Path()
                p.move(to: P(cx - 0.06, eyeY))
                p.addQuadCurve(to: P(cx + 0.06, eyeY), control: P(cx, eyeY + 0.055))
                ctx.stroke(p, with: .color(navy), style: StrokeStyle(lineWidth: lw * 1.3, lineCap: .round))
            } else {
                let w = 0.17 * s * eyeScale
                let h = 0.21 * s * eyeScale * CGFloat(eyeOpen)
                let white = Path(ellipseIn: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h))
                ctx.fill(white, with: .color(.white))
                ctx.stroke(white, with: .color(navy.opacity(0.35)), lineWidth: max(s * 0.01, 0.5))
                // pupil
                var lookX = mood == .idle ? sin(t * 0.7) * 0.015 : 0
                var lookY = 0.0
                if mood == .worried { lookY = -0.02; lookX = sin(t * 2) * 0.02 }
                let pw = 0.105 * s * eyeScale
                let ph2 = 0.125 * s * eyeScale * CGFloat(eyeOpen)
                let pc = CGPoint(x: center.x + CGFloat(lookX) * s, y: center.y + CGFloat(lookY) * s)
                ctx.fill(Path(ellipseIn: CGRect(x: pc.x - pw / 2, y: pc.y - ph2 / 2, width: pw, height: ph2)), with: .color(navy))
                // highlights
                let h1 = 0.04 * s * eyeScale
                ctx.fill(Path(ellipseIn: CGRect(x: pc.x - pw * 0.32, y: pc.y - ph2 * 0.38, width: h1, height: h1 * CGFloat(eyeOpen))), with: .color(.white))
                if s >= 24 {
                    let h2 = 0.02 * s * eyeScale
                    ctx.fill(Path(ellipseIn: CGRect(x: pc.x + pw * 0.1, y: pc.y + ph2 * 0.1, width: h2, height: h2 * CGFloat(eyeOpen))), with: .color(.white.opacity(0.9)))
                }
            }

            // brows
            if mood == .worried {
                var b = Path()
                b.move(to: P(0.5 + side * 0.07, 0.345))
                b.addLine(to: P(0.5 + side * 0.22, 0.395))
                ctx.stroke(b, with: .color(navy), style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))
            } else if mood == .alert {
                var b = Path()
                b.move(to: P(0.5 + side * 0.07, 0.36))
                b.addLine(to: P(0.5 + side * 0.22, 0.33))
                ctx.stroke(b, with: .color(navy), style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))
            }

            // cheeks
            let cc = P(0.5 + side * 0.245, 0.62)
            let cw = 0.095 * s, ch = 0.055 * s
            ctx.fill(Path(ellipseIn: CGRect(x: cc.x - cw / 2, y: cc.y - ch / 2, width: cw, height: ch)),
                     with: .color(cheek.opacity(mood == .worried ? 0.35 : 0.8)))
        }

        // MARK: mouth
        switch mood {
        case .idle:
            var m = Path()
            m.move(to: P(0.43, 0.615))
            m.addQuadCurve(to: P(0.57, 0.615), control: P(0.5, 0.70))
            ctx.stroke(m, with: .color(navy), style: StrokeStyle(lineWidth: lw, lineCap: .round))
        case .happy, .celebrating:
            var m = Path()
            m.move(to: P(0.41, 0.60))
            m.addQuadCurve(to: P(0.59, 0.60), control: P(0.5, 0.80))
            m.closeSubpath()
            ctx.fill(m, with: .color(navy))
            if s >= 24 {
                ctx.fill(Path(ellipseIn: CGRect(x: 0.46 * s, y: 0.665 * s, width: 0.08 * s, height: 0.035 * s)), with: .color(cheek))
            }
        case .alert:
            let w = 0.06 * s, h = 0.08 * s
            ctx.fill(Path(ellipseIn: CGRect(x: 0.5 * s - w / 2, y: 0.655 * s - h / 2, width: w, height: h)), with: .color(navy))
        case .sleepy:
            var m = Path()
            m.move(to: P(0.46, 0.63))
            m.addQuadCurve(to: P(0.54, 0.63), control: P(0.5, 0.665))
            ctx.stroke(m, with: .color(navy), style: StrokeStyle(lineWidth: lw, lineCap: .round))
        case .worried:
            var m = Path()
            m.move(to: P(0.44, 0.67))
            m.addQuadCurve(to: P(0.56, 0.67), control: P(0.5, 0.61))
            ctx.stroke(m, with: .color(navy), style: StrokeStyle(lineWidth: lw, lineCap: .round))
            // sweat drop
            let p = frac(t * 0.4)
            let dp = P(0.8, 0.30 + p * 0.16)
            let dw = 0.05 * s, dh = 0.07 * s
            ctx.fill(Path(ellipseIn: CGRect(x: dp.x - dw / 2, y: dp.y - dh / 2, width: dw, height: dh)),
                     with: .color(Color.cyan.opacity(0.9 * (1 - p * 0.6))))
        }

        // MARK: overlays above body (restore untransformed space)
        // Drawn in transformed space is fine here: positions are near the shield.
        if mood == .alert {
            let pulse = 1 + 0.12 * CGFloat(abs(sin(t * 8)))
            let br = s * 0.1 * pulse
            let bc = P(0.88, 0.16)
            ctx.fill(Path(ellipseIn: CGRect(x: bc.x - br, y: bc.y - br, width: br * 2, height: br * 2)), with: .color(.red))
            ctx.draw(Text("!").font(.system(size: max(s * 0.17, 7), weight: .heavy, design: .rounded)).foregroundColor(.white), at: bc)
        }

        if mood == .sleepy {
            for i in 0..<3 {
                let p = frac(t * 0.35 + Double(i) / 3.0)
                let pos = P(0.74 + p * 0.16, 0.32 - p * 0.26)
                let fs = max(s * (0.10 + 0.08 * p), 6)
                ctx.opacity = sin(p * Double.pi)
                ctx.draw(Text("z").font(.system(size: fs, weight: .bold, design: .rounded)).foregroundColor(Color.blue), at: pos)
            }
            ctx.opacity = 1
        }

        if mood == .celebrating {
            let spots: [(Double, Double)] = [(0.08, 0.2), (0.92, 0.22), (0.22, 0.04), (0.8, 0.05), (0.5, 0.0), (0.04, 0.5)]
            let colors: [Color] = [.yellow, .pink, .cyan, .orange, .yellow, .mint]
            for (i, spot) in spots.enumerated() {
                let tw = 0.5 + 0.5 * abs(sin(t * 5 + Double(i) * 1.3))
                let r = s * 0.07 * CGFloat(tw) + s * 0.015
                ctx.fill(star(at: P(spot.0, spot.1), radius: r), with: .color(colors[i]))
            }
        }
    }

    /// 4-point sparkle.
    static func star(at c: CGPoint, radius r: CGFloat) -> Path {
        var p = Path()
        let inner = r * 0.35
        for i in 0..<8 {
            let a = Double(i) * Double.pi / 4 - Double.pi / 2
            let rad = i % 2 == 0 ? r : inner
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rad, y: c.y + CGFloat(sin(a)) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
