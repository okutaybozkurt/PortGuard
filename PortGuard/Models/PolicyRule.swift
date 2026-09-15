import Foundation

/// Özellik 8 — A rule that triggers an alert or automatic kill when a process
/// exceeds a defined resource threshold.
public struct PolicyRule: Identifiable, Codable, Hashable {
    public let id: UUID
    public var processPattern: String      // partial match, e.g. "node", "python"
    public var conditionType: ConditionType
    public var threshold: Double           // MB for RAM, % for CPU, seconds for Uptime
    public var action: RuleAction
    public var isEnabled: Bool

    public enum ConditionType: String, Codable, CaseIterable, Identifiable {
        case ramMB   = "RAM (MB)"
        case cpuPct  = "CPU (%)"
        case uptime  = "Çalışma Süresi (dk)"

        public var id: String { rawValue }

        public var unit: String {
            switch self {
            case .ramMB:  return "MB"
            case .cpuPct: return "%"
            case .uptime: return "dk"
            }
        }

        public var iconName: String {
            switch self {
            case .ramMB:  return "memorychip"
            case .cpuPct: return "cpu"
            case .uptime: return "clock"
            }
        }

        public var defaultThreshold: Double {
            switch self {
            case .ramMB:  return 1024
            case .cpuPct: return 80
            case .uptime: return 60
            }
        }
    }

    public enum RuleAction: String, Codable, CaseIterable, Identifiable {
        case alert     = "Bildirim Gönder"
        case kill      = "Süreci Sonlandır"
        case alertKill = "Bildirim + Sonlandır"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .alert:     return "bell.badge.fill"
            case .kill:      return "xmark.circle.fill"
            case .alertKill: return "exclamationmark.triangle.fill"
            }
        }
    }

    public init(
        id: UUID = UUID(),
        processPattern: String = "",
        conditionType: ConditionType = .ramMB,
        threshold: Double = 1024,
        action: RuleAction = .alert,
        isEnabled: Bool = true
    ) {
        self.id             = id
        self.processPattern = processPattern
        self.conditionType  = conditionType
        self.threshold      = threshold
        self.action         = action
        self.isEnabled      = isEnabled
    }

    /// Human-readable description, e.g. "node → RAM ≥ 1024 MB → Sonlandır"
    public var summary: String {
        let pattern = processPattern.isEmpty ? "Tüm süreçler" : processPattern
        return "\(pattern) → \(conditionType.rawValue) ≥ \(Int(threshold)) \(conditionType.unit) → \(action.rawValue)"
    }
}

/// A rule violation detected during an evaluation cycle.
public struct RuleViolation: Identifiable {
    public let id = UUID()
    public let rule: PolicyRule
    public let process: PortProcess
    public let observedValue: Double

    public var description: String {
        let pattern = rule.processPattern.isEmpty ? process.processName : rule.processPattern
        return "\(pattern) (:\(process.port)) — \(rule.conditionType.rawValue): \(Int(observedValue)) \(rule.conditionType.unit)"
    }
}
