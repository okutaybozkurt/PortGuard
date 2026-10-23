import Foundation

/// `ps -ww -p <pid> -o ppid=,etime=,command=` ve `lsof -a -p <pid> -d cwd -Fn` çıktılarını ayrıştırır.
public struct ProcessDetailParser {
    public init() {}

    public struct PsLine: Equatable {
        public let ppid: Int
        public let elapsedSeconds: Double
        public let command: String
    }

    public func parsePs(_ raw: String) -> PsLine? {
        guard let line = raw.components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return nil }
        var rest = Substring(line.trimmingCharacters(in: .whitespaces))

        func nextToken() -> String? {
            guard !rest.isEmpty else { return nil }
            let end = rest.firstIndex(where: { $0 == " " || $0 == "\t" }) ?? rest.endIndex
            let token = String(rest[..<end])
            rest = rest[end...].drop(while: { $0 == " " || $0 == "\t" })
            return token
        }

        guard let ppidToken = nextToken(), let ppid = Int(ppidToken),
              let etimeToken = nextToken() else { return nil }
        let command = String(rest)
        guard !command.isEmpty else { return nil }
        return PsLine(ppid: ppid, elapsedSeconds: EtimeParser.parseSeconds(etimeToken), command: command)
    }

    /// lsof -F çıktısı: `p<pid>` / `fcwd` / `n<path>` satırları.
    public func parseCwd(_ raw: String) -> String? {
        var sawCwd = false
        for line in raw.components(separatedBy: .newlines) {
            if line == "fcwd" { sawCwd = true; continue }
            if sawCwd, line.hasPrefix("n") {
                let path = String(line.dropFirst())
                return path.isEmpty ? nil : path
            }
        }
        return nil
    }

    /// `sysctl KERN_PROCARGS2` tamponu: int32 argc, exec_path\0, NUL dolgusu, argc adet \0-sonlu argüman.
    public func parseProcArgs(_ buffer: [UInt8]) -> [String]? {
        guard buffer.count > 4 else { return nil }
        let argc = Int(buffer[0]) | Int(buffer[1]) << 8 | Int(buffer[2]) << 16 | Int(buffer[3]) << 24
        guard argc > 0 else { return nil }
        var i = 4
        while i < buffer.count, buffer[i] != 0 { i += 1 }      // exec_path
        while i < buffer.count, buffer[i] == 0 { i += 1 }      // dolgu
        var args: [String] = []
        while args.count < argc, i < buffer.count {
            var j = i
            while j < buffer.count, buffer[j] != 0 { j += 1 }
            args.append(String(decoding: buffer[i..<j], as: UTF8.self))
            i = j + 1
        }
        return args.count == argc ? args : nil
    }

    public func parseParentName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.split(separator: "/").last.map(String.init) ?? trimmed
    }

    public func parse(pid: Int, psOutput: String, lsofOutput: String, parentCommOutput: String, arguments: [String] = [], now: Date = Date()) -> ProcessDetail? {
        guard let ps = parsePs(psOutput) else { return nil }
        return ProcessDetail(
            pid: pid,
            ppid: ps.ppid,
            parentName: parseParentName(parentCommOutput),
            cwd: parseCwd(lsofOutput),
            command: arguments.isEmpty ? ps.command : arguments.joined(separator: " "),
            arguments: arguments,
            startedAt: ps.elapsedSeconds > 0 ? now.addingTimeInterval(-ps.elapsedSeconds) : nil
        )
    }
}
