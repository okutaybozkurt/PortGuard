import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "Sistem Varsayılanı"
    case light = "Açık Tema (Light)"
    case dark = "Karanlık Tema (Dark)"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
