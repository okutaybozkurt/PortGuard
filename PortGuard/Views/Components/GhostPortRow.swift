import SwiftUI

/// Özellik 2 — A placeholder row shown for pinned ports that are not currently active.
/// Visually indicates that a port is expected/watched but its process is not running.
public struct GhostPortRow: View {
    public let port: Int
    public let language: String
    public let onUnpin: () -> Void

    @State private var isHovered = false

    public init(port: Int, language: String = "tr", onUnpin: @escaping () -> Void) {
        self.port     = port
        self.language = language
        self.onUnpin  = onUnpin
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Pin indicator
            Image(systemName: "pin.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange.opacity(0.7))
                .padding(.leading, 4)

            // Port number (dimmed)
            Text(verbatim: "\(port)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .tracking(-0.4)
                .foregroundColor(.blue.opacity(0.4))
                .frame(width: 52, alignment: .leading)

            // Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text("Bekleniyor…".localized(language: language))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
                Text("Pinlenmiş — şu an aktif değil".localized(language: language))
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.tertiaryLabel)
            }

            Spacer()

            // Unpin button
            if isHovered {
                Button(action: onUnpin) {
                    Image(systemName: "pin.slash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.pressable)
                .help("Pini Kaldır".localized(language: language))
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Color.orange.opacity(isHovered ? 0.25 : 0.12),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                        )
                )
        )
        .onHover { hovering in
            withAnimation(.appleSpring) { isHovered = hovering }
        }
    }
}
