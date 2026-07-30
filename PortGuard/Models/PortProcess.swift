import Foundation

public struct PortProcess: Identifiable, Hashable, Equatable {
    public let id: String
    public let pid: Int
    public let processName: String
    public let user: String
    public let port: Int
    public let memoryMB: Double
    public let cpuPercent: Double
    public let isDevProcess: Bool

    public init(
        pid: Int,
        processName: String,
        user: String,
        port: Int,
        memoryMB: Double,
        cpuPercent: Double = 0.0,
        isDevProcess: Bool = true
    ) {
        self.id = "\(pid)-\(port)"
        self.pid = pid
        self.processName = processName
        self.user = user
        self.port = port
        self.memoryMB = memoryMB
        self.cpuPercent = cpuPercent
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
}
