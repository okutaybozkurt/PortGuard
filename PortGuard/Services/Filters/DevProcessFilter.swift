import Foundation

public protocol ProcessFilterStrategyProtocol {
    func isDevProcess(command: String) -> Bool
    func isSystemProcess(command: String) -> Bool
}

public final class DevProcessFilter: ProcessFilterStrategyProtocol {
    private let defaultDevKeywords: Set<String>
    private let systemBlacklist: Set<String>
    private var activeKeywords: Set<String>

    public init(customKeywords: [String] = []) {
        self.defaultDevKeywords = [
            "node", "dart", "python", "python3", "java", "go", "ruby",
            "postgres", "mysqld", "docker", "docker-proxy", "bun", "deno",
            "php", "rust", "cargo", "redis-server", "caddy", "nginx",
            "uvicorn", "gunicorn", "vite", "webpack", "next-server", "flutter",
            "elixir", "beam.smp"
        ]

        self.systemBlacklist = [
            // Internal macOS system services that clutter the list
            "controlcenter", "rapportd", "httpd", "launchd", "cupsd",
            "systemskype", "systemuiserver", "identityservicesd", "sharingd",
            "cloudd", "remotepairingd", "configd", "mdnsresponder", "locationd",
            "apsd", "nsurlsessiond", "syslogd", "opendirectoryd", "loginwindow"
        ]

        var combined = defaultDevKeywords
        for kw in customKeywords {
            let trimmed = kw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmed.isEmpty {
                combined.insert(trimmed)
            }
        }
        self.activeKeywords = combined
    }

    public func isSystemProcess(command: String) -> Bool {
        let lower = command.lowercased()
        for blacklisted in systemBlacklist {
            if lower.contains(blacklisted) {
                return true
            }
        }
        return false
    }

    public func isDevProcess(command: String) -> Bool {
        let lower = command.lowercased()

        if isSystemProcess(command: command) {
            return false
        }

        for keyword in activeKeywords {
            if lower.contains(keyword) {
                return true
            }
        }

        return false
    }
}
