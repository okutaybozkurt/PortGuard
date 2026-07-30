import SwiftUI

public struct StatCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let iconName: String
    public let iconColor: Color

    public init(title: String, value: String, subtitle: String, iconName: String, iconColor: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
    }

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(10)
    }
}
