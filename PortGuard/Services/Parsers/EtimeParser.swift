import Foundation

public enum EtimeParser {
    /// Parses macOS `ps -o etime=` output — format `[[DD-]HH:]MM:SS` — into elapsed seconds.
    public static func parseSeconds(_ raw: String) -> Double {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return 0 }

        var days = 0.0
        var rest = Substring(trimmed)
        if let dashIndex = trimmed.firstIndex(of: "-") {
            days = Double(trimmed[..<dashIndex]) ?? 0
            rest = trimmed[trimmed.index(after: dashIndex)...]
        }

        let components = rest.split(separator: ":").compactMap { Double($0) }
        guard !components.isEmpty else { return days * 86_400 }

        var hours = 0.0, minutes = 0.0, seconds = 0.0
        switch components.count {
        case 3:
            hours = components[0]; minutes = components[1]; seconds = components[2]
        case 2:
            minutes = components[0]; seconds = components[1]
        case 1:
            seconds = components[0]
        default:
            break
        }

        return days * 86_400 + hours * 3_600 + minutes * 60 + seconds
    }
}
