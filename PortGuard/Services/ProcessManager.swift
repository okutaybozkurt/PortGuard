import Foundation

public final class ProcessManager: ProcessServiceProtocol {
    public static let shared = ProcessManager()

    private let commandExecutor: CommandExecutorProtocol
    private let parser: LsofOutputParsingProtocol
    private let establishedParser: LsofEstablishedParser
    private let dockerService: DockerService

    public init(
        commandExecutor: CommandExecutorProtocol = ShellCommandExecutor(),
        parser: LsofOutputParsingProtocol = LsofOutputParser(),
        establishedParser: LsofEstablishedParser = LsofEstablishedParser(),
        dockerService: DockerService = DockerService.shared
    ) {
        self.commandExecutor = commandExecutor
        self.parser = parser
        self.establishedParser = establishedParser
        self.dockerService = dockerService
    }

    public func fetchActivePorts(showOnlyDev: Bool = true, customDevKeywords: [String] = []) -> [PortProcess] {
        let lsofOutput = commandExecutor.runCommand(
            executable: "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]
        )
        let pidMetricsMap = fetchAllPidMetricsMap()
        let pidCommandMap = fetchAllPidCommandMap()
        let filterStrategy = DevProcessFilter(customKeywords: customDevKeywords)

        var processes = parser.parse(
            lsofRawText: lsofOutput,
            pidMetricsMap: pidMetricsMap,
            pidCommandMap: pidCommandMap,
            filter: filterStrategy,
            showOnlyDev: showOnlyDev
        )

        // Özellik 3: Enrich with bandwidth metrics
        let bandwidthMap = fetchNetworkBandwidth(pids: processes.map(\.pid))
        processes = processes.map { proc in
            guard let bw = bandwidthMap[proc.pid] else { return proc }
            return PortProcess(
                pid: proc.pid,
                processName: proc.processName,
                user: proc.user,
                port: proc.port,
                memoryMB: proc.memoryMB,
                cpuPercent: proc.cpuPercent,
                uptimeSeconds: proc.uptimeSeconds,
                isDevProcess: proc.isDevProcess,
                isKillable: proc.isKillable,
                networkInBPS: bw.inBPS,
                networkOutBPS: bw.outBPS,
                dockerContainerName: proc.dockerContainerName
            )
        }

        // Özellik 7: Enrich with Docker container info
        processes = enrichWithDocker(processes)

        return processes
    }

    // MARK: - Özellik 1: ESTABLISHED Connections

    /// Returns active ESTABLISHED TCP connections (browser tabs, background syncs, etc.)
    public func fetchEstablishedConnections() -> [NetworkConnection] {
        let output = commandExecutor.runCommand(
            executable: "/usr/sbin/lsof",
            arguments: ["-iTCP", "-P", "-n"]
        )
        let pidCommandMap = fetchAllPidCommandMap()
        return establishedParser.parse(rawText: output, pidCommandMap: pidCommandMap)
    }

    // MARK: - Özellik 3: Bandwidth via nettop

    public struct BandwidthMetrics {
        public let inBPS: Double    // bytes per second inbound
        public let outBPS: Double   // bytes per second outbound
    }

    /// Fetch per-PID network bandwidth using `nettop`.
    /// We request 2 samples (-l 2) with a 1-second interval so we can compute
    /// (sample2 − sample1) = actual bytes transferred in that second → true BPS.
    /// Cumulative totals from a single sample are meaningless as a rate.
    /// Returns empty map if nettop is unavailable or no pids given.
    public func fetchNetworkBandwidth(pids: [Int]) -> [Int: BandwidthMetrics] {
        guard !pids.isEmpty else { return [:] }

        let nettopPath = "/usr/bin/nettop"
        guard FileManager.default.fileExists(atPath: nettopPath) else { return [:] }

        // -l 2: capture two snapshots separated by 1 second (default interval)
        // -J bytes_in,bytes_out: only the columns we need
        // -P: per-process mode
        let output = commandExecutor.runCommand(
            executable: nettopPath,
            arguments: ["-P", "-l", "2", "-J", "bytes_in,bytes_out"]
        )

        return parseNettopDeltaOutput(output, filterPids: Set(pids))
    }

    // MARK: - Özellik 7: Docker enrichment

    /// Enriches PortProcess list with Docker container names when the port is served
    /// by a Docker container. Requires Docker to be running; silently returns original
    /// list otherwise.
    public func enrichWithDocker(_ processes: [PortProcess]) -> [PortProcess] {
        guard dockerService.isDockerAvailable() else { return processes }
        let portMap = dockerService.buildPortToContainerMap()

        return processes.map { proc in
            guard let container = portMap[proc.port] else { return proc }
            return PortProcess(
                pid: proc.pid,
                processName: proc.processName,
                user: proc.user,
                port: proc.port,
                memoryMB: proc.memoryMB,
                cpuPercent: proc.cpuPercent,
                uptimeSeconds: proc.uptimeSeconds,
                isDevProcess: proc.isDevProcess,
                isKillable: proc.isKillable,
                networkInBPS: proc.networkInBPS,
                networkOutBPS: proc.networkOutBPS,
                dockerContainerName: container.name
            )
        }
    }

    // MARK: - Kill

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

    // MARK: - Private helpers

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

    /// Parse two-sample nettop output and compute delta BPS.
    /// nettop separates samples with blank lines or header repetitions.
    /// We collect per-PID values for each sample, then BPS = (sample2 − sample1) / 1s.
    private func parseNettopDeltaOutput(_ raw: String, filterPids: Set<Int>) -> [Int: BandwidthMetrics] {
        let lines = raw.components(separatedBy: .newlines)

        // Split into blocks by detecting repeated header lines (contain "bytes_in")
        // or blank-line delimiters between nettop samples.
        var blocks: [[String]] = [[]]
        for line in lines {
            // A new header signals a new sample block
            if line.contains("bytes_in") && line.contains("bytes_out") && !line.hasPrefix(" ") && blocks.last?.isEmpty == false {
                blocks.append([])
            }
            blocks[blocks.count - 1].append(line)
        }

        // We need at least 2 blocks to compute a delta
        guard blocks.count >= 2 else {
            // Fall back: report the last block's values as-is (better than nothing)
            return parseNettopBlock(blocks.last ?? [], filterPids: filterPids)
        }

        let sample1 = parseNettopBlock(blocks[blocks.count - 2], filterPids: filterPids)
        let sample2 = parseNettopBlock(blocks[blocks.count - 1], filterPids: filterPids)

        var result: [Int: BandwidthMetrics] = [:]
        for pid in filterPids {
            let in1  = sample1[pid]?.inBPS  ?? 0
            let out1 = sample1[pid]?.outBPS ?? 0
            let in2  = sample2[pid]?.inBPS  ?? 0
            let out2 = sample2[pid]?.outBPS ?? 0
            // Delta is bytes transferred in the ~1 second interval
            let deltaIn  = max(0, in2  - in1)
            let deltaOut = max(0, out2 - out1)
            if deltaIn > 0 || deltaOut > 0 {
                result[pid] = BandwidthMetrics(inBPS: deltaIn, outBPS: deltaOut)
            }
        }
        return result
    }

    private func parseNettopBlock(_ lines: [String], filterPids: Set<Int>) -> [Int: BandwidthMetrics] {
        var result: [Int: BandwidthMetrics] = [:]
        for line in lines {
            guard let pid = extractPidFromNettopLine(line), filterPids.contains(pid) else { continue }
            let inVal  = extractNettopValue(key: "bytes_in",  from: line)
            let outVal = extractNettopValue(key: "bytes_out", from: line)
            result[pid] = BandwidthMetrics(inBPS: inVal, outBPS: outVal)
        }
        return result
    }

    private func extractPidFromNettopLine(_ line: String) -> Int? {
        // nettop prints "processname.PID" as first token
        let token = line.split(separator: " ", omittingEmptySubsequences: true).first.map(String.init) ?? ""
        if let dotIdx = token.lastIndex(of: ".") {
            let pidStr = String(token[token.index(after: dotIdx)...])
            return Int(pidStr)
        }
        return Int(token)
    }

    private func extractNettopValue(key: String, from line: String) -> Double {
        // Matches "bytes_in=102400" or "bytes_in: 102400"
        let pattern = "\(key)[=: ]+(\\d+)"
        if let range = line.range(of: pattern, options: .regularExpression) {
            let match = String(line[range])
            let digits = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            return Double(digits) ?? 0
        }
        return 0
    }
}
