import Foundation

/// Parses `lsof -iTCP -sTCP:ESTABLISHED,CLOSE_WAIT,TIME_WAIT,SYN_SENT -P -n` output
/// into `[NetworkConnection]` objects.
///
/// Key accuracy improvements vs. the previous version:
///   - Uses `-sTCP:...` flag at the call site so lsof pre-filters states (no LISTEN rows leak in)
///   - Parses the NAME column by scanning backwards instead of relying on a fixed index,
///     which breaks if lsof adds extra columns (e.g. file size/offset differs by OS version)
///   - Deduplicates by (pid, localPort, remoteAddr, remotePort) so the same socket
///     doesn't appear twice when lsof emits multiple FD rows for one process
public final class LsofEstablishedParser {
    public init() {}

    /// Parse raw lsof output.
    /// - Parameters:
    ///   - rawText: stdout from `lsof -iTCP -P -n` (all TCP states)
    ///   - pidCommandMap: PID → full process name from `ps -eo pid=,comm=`
    public func parse(
        rawText: String,
        pidCommandMap: [Int: String] = [:]
    ) -> [NetworkConnection] {
        var results: [NetworkConnection] = []
        var seenKeys = Set<String>()

        let lines = rawText.components(separatedBy: .newlines)

        for line in lines.dropFirst() {            // drop header
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            // ── Extract the TCP state from the trailing "(STATE)" token ──
            // This is the most reliable approach — the state is always parenthesised
            // at the end of the NAME column, regardless of how many columns precede it.
            let stateString: String
            if let match = line.range(of: #"\((\w+)\)$"#, options: .regularExpression) {
                stateString = String(line[match])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            } else {
                continue   // no state = LISTEN or non-TCP row → skip
            }

            let state = NetworkConnection.ConnectionState(rawString: stateString)
            guard state == .established || state == .closeWait || state == .timeWait || state == .synSent else {
                continue
            }

            // ── Split into whitespace-separated tokens ──
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            // Minimum: COMMAND PID USER FD TYPE DEVICE SIZE NODE NAME → 9 cols
            guard parts.count >= 9 else { continue }

            let rawCommand = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let user = parts[2]

            // ── NAME column: scan right-to-left for "addr:port->addr:port (STATE)" ──
            // We look for the token that contains "->" to find the connection endpoints.
            // This is robust against lsof adding/removing intermediate columns.
            guard let nameToken = parts.first(where: { $0.contains("->") }) else { continue }

            let arrow = nameToken.components(separatedBy: "->")
            guard arrow.count == 2 else { continue }

            let localPart  = arrow[0]
            // Remote part may still have trailing " (STATE)" if it wasn't already stripped
            let remotePart = arrow[1].components(separatedBy: " ").first ?? arrow[1]

            guard let (localAddr, localPort)   = parseEndpoint(localPart),
                  let (remoteAddr, remotePort) = parseEndpoint(remotePart) else { continue }

            // Skip loopback-only (127.x or ::1 to ::1) — usually internal IPC, rarely interesting
            // but keep them if local addr is also loopback (e.g. DB connections to localhost)

            let effectiveCommand = pidCommandMap[pid] ?? rawCommand

            let key = "\(pid)-\(localPort)-\(remoteAddr)-\(remotePort)"
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)

            results.append(NetworkConnection(
                pid: pid,
                processName: effectiveCommand,
                user: user,
                localAddress: localAddr,
                localPort: localPort,
                remoteAddress: remoteAddr,
                remotePort: remotePort,
                state: state
            ))
        }

        // Sort: ESTABLISHED first, then alphabetically by process name
        return results.sorted {
            if $0.state == .established && $1.state != .established { return true }
            if $0.state != .established && $1.state == .established { return false }
            return $0.processName < $1.processName
        }
    }

    // MARK: - Private helpers

    /// Parse "address:port" or "[::1]:port" or "*:port" → (address, port)
    private func parseEndpoint(_ raw: String) -> (String, Int)? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        // IPv6 bracket format: [::1]:443 or [2001:db8::1]:8080
        if trimmed.hasPrefix("[") {
            guard let closeBracket = trimmed.firstIndex(of: "]") else { return nil }
            let addrPart = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closeBracket])
            let afterBracket = String(trimmed[trimmed.index(after: closeBracket)...])
            guard afterBracket.hasPrefix(":"),
                  let port = Int(afterBracket.dropFirst()) else { return nil }
            return (addrPart.isEmpty ? "::1" : addrPart, port)
        }

        // Standard IPv4 / hostname: 192.168.1.1:443 or *:80
        // Use lastIndex to handle IPv4-mapped IPv6 like "::ffff:1.2.3.4:443"
        guard let colonIdx = trimmed.lastIndex(of: ":") else { return nil }
        let portStr = String(trimmed[trimmed.index(after: colonIdx)...])
        guard let port = Int(portStr) else { return nil }
        let addr = String(trimmed[..<colonIdx])
        return (addr.isEmpty || addr == "*" ? "localhost" : addr, port)
    }
}
