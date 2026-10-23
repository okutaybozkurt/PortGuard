import Foundation

public final class ProcessDetailService: ProcessDetailProviding, PortAvailabilityChecking {
    private let executor: CommandExecutorProtocol
    private let parser: ProcessDetailParser
    private let argumentsReader: (Int) -> [String]?

    public init(
        executor: CommandExecutorProtocol = ShellCommandExecutor(),
        parser: ProcessDetailParser = ProcessDetailParser(),
        argumentsReader: ((Int) -> [String]?)? = nil
    ) {
        self.executor = executor
        self.parser = parser
        self.argumentsReader = argumentsReader ?? { pid in
            guard let buf = ProcessDetailService.readProcArgs(pid: pid) else { return nil }
            return ProcessDetailParser().parseProcArgs(buf)
        }
    }

    public func fetchDetail(pid: Int) -> ProcessDetail? {
        let ps = executor.runCommand(executable: "/bin/ps", arguments: ["-ww", "-p", "\(pid)", "-o", "ppid=,etime=,command="])
        guard let line = parser.parsePs(ps) else { return nil }
        let lsof = executor.runCommand(executable: "/usr/sbin/lsof", arguments: ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"])
        let parent = executor.runCommand(executable: "/bin/ps", arguments: ["-p", "\(line.ppid)", "-o", "comm="])
        return parser.parse(pid: pid, psOutput: ps, lsofOutput: lsof, parentCommOutput: parent,
                            arguments: argumentsReader(pid) ?? [])
    }

    public func listeningPIDs(on port: Int) -> Set<Int> {
        let out = executor.runCommand(executable: "/usr/sbin/lsof", arguments: ["-iTCP:\(port)", "-sTCP:LISTEN", "-P", "-n", "-t"])
        return Set(out.split(whereSeparator: \.isNewline).compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }

    /// KERN_PROCARGS2 ham tamponu (aynı kullanıcının süreçleri için).
    static func readProcArgs(pid: Int) -> [UInt8]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, Int32(pid)]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return nil }
        return Array(buffer.prefix(size))
    }
}

/// argv'yi shell string'ine ASLA birleştirmeden çalıştırır:
/// `/bin/zsh -lc 'exec "$@"' zsh <argv0> <argv1...>` — argümanlar Process.arguments ile geçer.
public final class DetachedShellLauncher: ProcessLaunching {
    public init() {}

    public static func shellArguments(for argv: [String]) -> [String] {
        ["-lc", "exec \"$@\"", "zsh"] + argv
    }

    public static func makeProcess(argv: [String], workingDirectory: String) -> Process {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = shellArguments(for: argv)
        task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
        task.standardInput = FileHandle.nullDevice
        return task
    }

    public func launch(arguments: [String], workingDirectory: String) -> Result<String, ProcessRestartError> {
        guard !arguments.isEmpty else { return .failure(.launchFailed(logPath: nil)) }
        let logPath = NSTemporaryDirectory() + "portguard-restart-\(UUID().uuidString).log"
        FileManager.default.createFile(atPath: logPath, contents: nil, attributes: [.posixPermissions: 0o600])
        let task = Self.makeProcess(argv: arguments, workingDirectory: workingDirectory)
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle(forWritingAtPath: logPath) ?? FileHandle.nullDevice
        do {
            try task.run()
            return .success(logPath)
        } catch {
            return .failure(.launchFailed(logPath: logPath))
        }
    }
}
