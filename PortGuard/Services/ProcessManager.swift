import Foundation

public final class ProcessManager {
    public static let shared = ProcessManager()

    private let devKeywords: Set<String> = [
        "node", "dart", "python", "python3", "java", "go", "ruby",
        "postgres", "mysqld", "docker", "docker-proxy", "bun", "deno",
        "php", "rust", "cargo", "redis-server", "caddy", "nginx",
        "uvicorn", "gunicorn", "vite", "webpack", "next-server", "flutter"
    ]

    private let systemBlacklist: Set<String> = [
        "controlcenter", "rapportd", "httpd", "launchd", "cupsd",
        "systemskype", "systemuiserver", "identityservicesd", "sharingd",
        "cloudd", "remotepairingd", "configd", "mDNSResponder"
    ]

    private init() {}

    public func fetchActivePorts(showOnlyDev: Bool = true) -> [PortProcess] {
        let lsofOutput = runCommand(executable: "/usr/sbin/lsof", arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"])
        let pidMemoryMap = fetchAllPidMemoryMap()
        
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

            let isDev = isDeveloperProcess(command: rawCommand)
            if showOnlyDev && !isDev {
                continue
            }

            let memoryMB = pidMemoryMap[pid] ?? getSingleMemoryUsageMB(pid: pid)
            let item = PortProcess(
                pid: pid,
                processName: rawCommand,
                user: user,
                port: port,
                memoryMB: memoryMB,
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

    private func isDeveloperProcess(command: String) -> Bool {
        let lower = command.lowercased()
        if systemBlacklist.contains(lower) {
            return false
        }
        for keyword in devKeywords {
            if lower.contains(keyword) {
                return true
            }
        }
        return false
    }

    private func fetchAllPidMemoryMap() -> [Int: Double] {
        let output = runCommand(executable: "/bin/ps", arguments: ["-eo", "pid=,rss="])
        var map: [Int: Double] = [:]

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2,
                  let pid = Int(parts[0]),
                  let kb = Double(parts[1]) else { continue }
            map[pid] = kb / 1024.0
        }
        return map
    }

    private func getSingleMemoryUsageMB(pid: Int) -> Double {
        let output = runCommand(executable: "/bin/ps", arguments: ["-o", "rss=", "-p", "\(pid)"])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if let kb = Double(trimmed) {
            return kb / 1024.0
        }
        return 0.0
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
