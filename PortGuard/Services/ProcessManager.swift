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
        let pidCommandMap = fetchAllPidCommandMap()
        let filterStrategy = DevProcessFilter(customKeywords: customDevKeywords)

        return parser.parse(
            lsofRawText: lsofOutput,
            pidMetricsMap: pidMetricsMap,
            pidCommandMap: pidCommandMap,
            filter: filterStrategy,
            showOnlyDev: showOnlyDev
        )
    }

    public func killProcess(pid: Int) -> Bool {
        // SIGTERM, not SIGKILL: lets the process release its port and flush/close its own
        // state (DB connections, file handles) before exiting, instead of dying mid-operation.
        // Any well-behaved dev server (node, python, vite, docker containers, ...) honors this.
        let output = commandExecutor.runCommand(
            executable: "/bin/kill",
            arguments: ["-15", "\(pid)"]
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

    /// `lsof`'s COMMAND column is truncated to 9 characters (e.g. Docker Desktop's host-side
    /// forwarder "com.docker.backend" becomes "com.docke"), which silently breaks dev-keyword
    /// matching for container-published ports. `ps -eo comm=` returns the full executable path
    /// per PID, untruncated, so we use its last path component as the real process name.
    private func fetchAllPidCommandMap() -> [Int: String] {
        let output = commandExecutor.runCommand(
            executable: "/bin/ps",
            arguments: ["-eo", "pid=,comm="]
        )
        var map: [Int: String] = [:]

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            guard parts.count >= 2, let pid = Int(parts[0]) else { continue }
            let fullPath = parts[1...].joined(separator: " ")
            let lastComponent = fullPath.split(separator: "/").last.map(String.init) ?? fullPath
            map[pid] = lastComponent
        }
        return map
    }
}
