import SwiftUI

public enum AppleTheme {
    // Apple HIG Colors
    public static var windowBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }

    public static var controlBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }

    public static var secondaryBackground: Color {
        Color(NSColor.underPageBackgroundColor)
    }

    public static var label: Color {
        Color(NSColor.labelColor)
    }

    public static var secondaryLabel: Color {
        Color(NSColor.secondaryLabelColor)
    }

    public static var tertiaryLabel: Color {
        Color(NSColor.tertiaryLabelColor)
    }

    public static var separator: Color {
        Color(NSColor.separatorColor).opacity(0.6)
    }

    public static var accentBlue: Color {
        Color.blue
    }

    public static var accentOrange: Color {
        Color.orange
    }

    public static var accentRed: Color {
        Color.red
    }

    public static var accentGreen: Color {
        Color.green
    }

    public static var accentPurple: Color {
        Color.purple
    }
}

public extension Animation {
    /// Apple's default critically-damped UI spring — settles without overshoot.
    static var appleSpring: Animation {
        .spring(response: 0.32, dampingFraction: 1.0)
    }
}

public extension View {
    func appleCardStyle(hovered: Bool = false) -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor).opacity(hovered ? 0.7 : 0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(hovered ? Color.accentColor.opacity(0.35) : AppleTheme.separator, lineWidth: hovered ? 1 : 0.8)
            )
    }

    func appleBadgeStyle(color: Color = .blue) -> some View {
        self
            .font(.caption2)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(5)
    }
}

/// Instant, continuous press feedback per Apple's "respond on pointer-down" principle.
/// Scales down the instant the pointer is down and springs back on release — no waiting for click-up.
public struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    public init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.appleSpring, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
