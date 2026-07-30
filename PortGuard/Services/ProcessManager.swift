import Foundation

public final class ProcessManager: ProcessServiceProtocol {
    public static let shared = ProcessManager()

    private let commandExecutor: CommandExecutorProtocol
    private let parser: LsofOutputParsingProtocol

    public init(
        commandExecutor: CommandExecutorProtocol = ShellCommandExecutor(),
        parser: LsofOutputParsingProtocol = LsofOutputParser()
    ) {
        self.commandExecutor = commandExecutor
        self.parser = parser
    }

    public func fetchActivePorts(showOnlyDev: Bool = true, customDevKeywords: [String] = []) -> [PortProcess] {
        let lsofOutput = commandExecutor.runCommand(
            executable: "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]
        )
        let pidMetricsMap = fetchAllPidMetricsMap()
        let filterStrategy = DevProcessFilter(customKeywords: customDevKeywords)

        return parser.parse(
            lsofRawText: lsofOutput,
            pidMetricsMap: pidMetricsMap,
            filter: filterStrategy,
            showOnlyDev: showOnlyDev
        )
    }

    public func killProcess(pid: Int) -> Bool {
        let output = commandExecutor.runCommand(
            executable: "/bin/kill",
            arguments: ["-9", "\(pid)"]
        )
        _ = output
        return true
    }

    private func fetchAllPidMetricsMap() -> [Int: ProcessMetrics] {
        let output = commandExecutor.runCommand(
            executable: "/bin/ps",
            arguments: ["-eo", "pid=,%cpu=,rss=,etime="]
        )
        var map: [Int: ProcessMetrics] = [:]

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3,
                  let pid = Int(parts[0]),
                  let cpu = Double(parts[1]),
                  let kb = Double(parts[2]) else { continue }
            let uptime = parts.count >= 4 ? EtimeParser.parseSeconds(String(parts[3])) : 0
            map[pid] = ProcessMetrics(memoryMB: kb / 1024.0, cpuPercent: cpu, uptimeSeconds: uptime)
        }
        return map
    }
}
