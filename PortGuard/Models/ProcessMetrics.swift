import Foundation

public struct ProcessMetrics: Sendable, Hashable {
    public let memoryMB: Double
    public let cpuPercent: Double

    public init(memoryMB: Double, cpuPercent: Double) {
        self.memoryMB = memoryMB
        self.cpuPercent = cpuPercent
    }
}
