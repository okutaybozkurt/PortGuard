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
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .tracking(0.4)

                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(AppleTheme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppleTheme.separator, lineWidth: 0.8)
        )
    }
}
