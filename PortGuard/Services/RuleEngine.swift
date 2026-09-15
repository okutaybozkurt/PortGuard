import Foundation

/// Özellik 8 — Evaluates a list of `PolicyRule` against active processes
/// and returns violations that require action.
public final class RuleEngine {
    public static let shared = RuleEngine()
    public init() {}

    // MARK: - Evaluation

    /// Evaluate all enabled rules against the current process list.
    /// Returns one `RuleViolation` per (rule × process) pair that exceeds the threshold.
    public func evaluate(
        processes: [PortProcess],
        rules: [PolicyRule]
    ) -> [RuleViolation] {
        var violations: [RuleViolation] = []

        for rule in rules where rule.isEnabled {
            for process in processes {
                // Pattern matching: empty pattern matches all processes
                if !rule.processPattern.isEmpty {
                    let pattern = rule.processPattern.lowercased()
                    guard process.processName.lowercased().contains(pattern) else { continue }
                }

                let observed = observedValue(for: rule.conditionType, process: process)
                if observed >= rule.threshold {
                    violations.append(RuleViolation(
                        rule: rule,
                        process: process,
                        observedValue: observed
                    ))
                }
            }
        }

        return violations
    }

    // MARK: - Storage (UserDefaults)

    private let storageKey = "portguard.policyRules"

    public func loadRules() -> [PolicyRule] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let rules = try? JSONDecoder().decode([PolicyRule].self, from: data) else {
            return defaultRules()
        }
        return rules
    }

    public func saveRules(_ rules: [PolicyRule]) {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Private

    private func observedValue(for condition: PolicyRule.ConditionType, process: PortProcess) -> Double {
        switch condition {
        case .ramMB:  return process.memoryMB
        case .cpuPct: return process.cpuPercent
        case .uptime: return process.uptimeSeconds / 60.0  // convert to minutes
        }
    }

    /// Sensible built-in rules shown on first launch.
    private func defaultRules() -> [PolicyRule] {
        [
            PolicyRule(
                processPattern: "",
                conditionType: .ramMB,
                threshold: 2048,
                action: .alert,
                isEnabled: true
            ),
            PolicyRule(
                processPattern: "node",
                conditionType: .uptime,
                threshold: 1440,     // 24 hours in minutes
                action: .alert,
                isEnabled: false
            )
        ]
    }
}
