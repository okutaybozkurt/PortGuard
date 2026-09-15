import Foundation

public struct PortProcess: Identifiable, Hashable, Equatable {
    public let id: String
    public let pid: Int
    public let processName: String
    public let user: String
    public let port: Int
    public let memoryMB: Double
    public let cpuPercent: Double
    public let uptimeSeconds: Double
    public let isDevProcess: Bool
    public let isKillable: Bool

    // Özellik 3: Bandwidth (bytes/sec)
    public let networkInBPS: Double
    public let networkOutBPS: Double

    // Özellik 7: Docker container awareness
    public let dockerContainerName: String?

    public init(
        pid: Int,
        processName: String,
        user: String,
        port: Int,
        memoryMB: Double,
        cpuPercent: Double = 0.0,
        uptimeSeconds: Double = 0,
        isDevProcess: Bool = true,
        isKillable: Bool = true,
        networkInBPS: Double = 0.0,
        networkOutBPS: Double = 0.0,
        dockerContainerName: String? = nil
    ) {
        self.id = "\(pid)-\(port)"
        self.pid = pid
        self.processName = processName
        self.user = user
        self.port = port
        self.memoryMB = memoryMB
        self.cpuPercent = cpuPercent
        self.uptimeSeconds = uptimeSeconds
        self.isDevProcess = isDevProcess
        self.isKillable = isKillable
        self.networkInBPS = networkInBPS
        self.networkOutBPS = networkOutBPS
        self.dockerContainerName = dockerContainerName
    }

    public var formattedMemory: String {
        if memoryMB >= 1024 {
            return String(format: "%.2f GB", memoryMB / 1024.0)
        } else {
            return String(format: "%.1f MB", memoryMB)
        }
    }

    public var formattedCPU: String {
        return String(format: "%.1f%%", cpuPercent)
    }

    /// Formatted inbound network speed, e.g. "↓ 1.2 MB/s"
    public var formattedNetworkIn: String {
        "↓ " + formatBPS(networkInBPS)
    }

    /// Formatted outbound network speed, e.g. "↑ 340 KB/s"
    public var formattedNetworkOut: String {
        "↑ " + formatBPS(networkOutBPS)
    }

    /// True when there is measurable network activity
    public var hasNetworkActivity: Bool {
        networkInBPS > 0 || networkOutBPS > 0
    }

    private func formatBPS(_ bps: Double) -> String {
        if bps >= 1_048_576 {
            return String(format: "%.1f MB/s", bps / 1_048_576)
        } else if bps >= 1024 {
            return String(format: "%.0f KB/s", bps / 1024)
        } else if bps > 0 {
            return String(format: "%.0f B/s", bps)
        } else {
            return "0 B/s"
        }
    }

    public var formattedUptime: String {
        let totalMinutes = Int(uptimeSeconds / 60)
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 { return "\(days)g \(hours)s" }
        if hours > 0 { return "\(hours)s \(minutes)dk" }
        return "\(minutes)dk"
    }

    /// 1 günden uzun süredir açık — muhtemelen unutulmuş bir arka plan süreci.
    public var isLongRunning: Bool {
        uptimeSeconds >= 86_400
    }
}
