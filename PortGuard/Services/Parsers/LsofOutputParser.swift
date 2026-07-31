import Foundation

public protocol LsofOutputParsingProtocol {
    func parse(
        lsofRawText: String,
        pidMetricsMap: [Int: ProcessMetrics],
        pidCommandMap: [Int: String],
        filter: ProcessFilterStrategyProtocol,
        showOnlyDev: Bool
    ) -> [PortProcess]
}

public final class LsofOutputParser: LsofOutputParsingProtocol {
    public init() {}

    public func parse(
        lsofRawText: String,
        pidMetricsMap: [Int: ProcessMetrics],
        pidCommandMap: [Int: String] = [:],
        filter: ProcessFilterStrategyProtocol,
        showOnlyDev: Bool
    ) -> [PortProcess] {
        var results: [PortProcess] = []
        var seenKeys = Set<String>()

        let lines = lsofRawText.components(separatedBy: .newlines)
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

            // lsof truncates COMMAND to 9 chars (e.g. "com.docker.backend" -> "com.docke"),
            // which breaks keyword matching for Docker-forwarded ports. `ps -eo comm=` gives
            // the untruncated name, so prefer it when available.
            let effectiveCommand = pidCommandMap[pid] ?? rawCommand

            // 1. ALWAYS filter out noisy macOS system processes
            if filter.isSystemProcess(command: effectiveCommand) {
                continue
            }

            // 2. Check if it's a dev process
            let isDev = filter.isDevProcess(command: effectiveCommand)

            // 3. If "Sadece Dev" is checked, hide non-dev processes (like Spotify, Safari, Chrome)
            if showOnlyDev && !isDev {
                continue
            }

            // 4. Shared proxy processes (e.g. Docker Desktop's single port-forwarding backend)
            // stay visible but are never killable — one PID serves many unrelated ports/containers.
            let isKillable = !filter.isProtectedSharedProcess(command: effectiveCommand)

            let metrics = pidMetricsMap[pid] ?? ProcessMetrics(memoryMB: 0.0, cpuPercent: 0.0)
            let item = PortProcess(
                pid: pid,
                processName: effectiveCommand,
                user: user,
                port: port,
                memoryMB: metrics.memoryMB,
                cpuPercent: metrics.cpuPercent,
                uptimeSeconds: metrics.uptimeSeconds,
                isDevProcess: isDev,
                isKillable: isKillable
            )
            results.append(item)
        }

        return results.sorted { $0.port < $1.port }
    }
}
