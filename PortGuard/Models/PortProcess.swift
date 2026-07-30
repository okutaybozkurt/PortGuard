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

    public init(
        pid: Int,
        processName: String,
        user: String,
        port: Int,
        memoryMB: Double,
        cpuPercent: Double = 0.0,
        uptimeSeconds: Double = 0,
        isDevProcess: Bool = true
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
