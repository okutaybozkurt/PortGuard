import Foundation

public protocol LsofOutputParsingProtocol {
    func parse(
        lsofRawText: String,
        pidMetricsMap: [Int: ProcessMetrics],
        filter: ProcessFilterStrategyProtocol,
        showOnlyDev: Bool
    ) -> [PortProcess]
}

public final class LsofOutputParser: LsofOutputParsingProtocol {
    public init() {}

    public func parse(
        lsofRawText: String,
        pidMetricsMap: [Int: ProcessMetrics],
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

            let isDev = filter.isDevProcess(command: rawCommand)
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
                uptimeSeconds: metrics.uptimeSeconds,
                isDevProcess: isDev
            )
            results.append(item)
        }

        return results.sorted { $0.port < $1.port }
    }
}
