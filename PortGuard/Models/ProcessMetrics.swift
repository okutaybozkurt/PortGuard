import Foundation

public struct ProcessMetrics: Sendable, Hashable {
    public let memoryMB: Double
    public let cpuPercent: Double
    public let uptimeSeconds: Double

    public init(memoryMB: Double, cpuPercent: Double, uptimeSeconds: Double = 0) {
        self.memoryMB = memoryMB
        self.cpuPercent = cpuPercent
        self.uptimeSeconds = uptimeSeconds
    }
}
