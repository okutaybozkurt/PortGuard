import Foundation

public struct ProcessMetrics {
    public let memoryMB: Double
    public let cpuPercent: Double
}

public final class ProcessManager {
    public static let shared = ProcessManager()

    private var defaultDevKeywords: Set<String> = [
        "node", "dart", "python", "python3", "java", "go", "ruby",
        "postgres", "mysqld", "docker", "docker-proxy", "bun", "deno",
        "php", "rust", "cargo", "redis-server", "caddy", "nginx",
        "uvicorn", "gunicorn", "vite", "webpack", "next-server", "flutter",
        "elixir", "beam.smp"
    ]

    private let systemBlacklist: Set<String> = [
        "controlcenter", "rapportd", "httpd", "launchd", "cupsd",
        "systemskype", "systemuiserver", "identityservicesd", "sharingd",
        "cloudd", "remotepairingd", "configd", "mdnsresponder"
    ]

    private init() {}

    public func fetchActivePorts(showOnlyDev: Bool = true, customDevKeywords: [String] = []) -> [PortProcess] {
        let lsofOutput = runCommand(executable: "/usr/sbin/lsof", arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"])
        let pidMetricsMap = fetchAllPidMetricsMap()
        
        var activeKeywords = defaultDevKeywords
        for kw in customDevKeywords {
            let trimmed = kw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmed.isEmpty {
                activeKeywords.insert(trimmed)
            }
        }

        var results: [PortProcess] = []
        var seenKeys = Set<String>()

        let lines = lsofOutput.components(separatedBy: .newlines)
        for line in lines.dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            guard parts.count >= 9 else { continue }

            let rawCommand = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let user = parts[2]
            let nameField = parts[8] // e.g. *:3000, 127.0.0.1:8080, [::1]:5432

            let portString = nameField.components(separatedBy: ":").last ?? ""
            guard let port = Int(portString) else { continue }

            let uniqueKey = "\(pid)-\(port)"
            if seenKeys.contains(uniqueKey) { continue }
            seenKeys.insert(uniqueKey)

            let isDev = isDeveloperProcess(command: rawCommand, activeKeywords: activeKeywords)
            if showOnlyDev && !isDev {
                continue
            }

            let metrics = pidMetricsMap[pid] ?? ProcessMetrics(memoryMB: 0.0, cpuPercent: 0.0)
            let item = PortProcess(
                pid: pid,
                processName: rawCommand,
                user: user,
                port: port,
                memoryMB: metrics.memoryMB,
                cpuPercent: metrics.cpuPercent,
                isDevProcess: isDev
            )
            results.append(item)
        }

        return results.sorted { $0.port < $1.port }
    }

    public func killProcess(pid: Int) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/kill")
        task.arguments = ["-9", "\(pid)"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Process terminate error: \(error)")
            return false
        }
    }

    private func isDeveloperProcess(command: String, activeKeywords: Set<String>) -> Bool {
        let lower = command.lowercased()
        if systemBlacklist.contains(lower) {
            return false
        }
        for keyword in activeKeywords {
            if lower.contains(keyword) {
                return true
            }
        }
        return false
    }

    private func fetchAllPidMetricsMap() -> [Int: ProcessMetrics] {
        let output = runCommand(executable: "/bin/ps", arguments: ["-eo", "pid=,%cpu=,rss="])
        var map: [Int: ProcessMetrics] = [:]

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3,
                  let pid = Int(parts[0]),
                  let cpu = Double(parts[1]),
                  let kb = Double(parts[2]) else { continue }
            map[pid] = ProcessMetrics(memoryMB: kb / 1024.0, cpuPercent: cpu)
        }
        return map
    }

    private func runCommand(executable: String, arguments: [String]) -> String {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
