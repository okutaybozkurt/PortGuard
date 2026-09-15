import Foundation

/// Özellik 6 — A snapshot of active port processes captured at a single point in time.
/// Stored periodically by `HistoryStore` to enable usage graphs and weekly summaries.
public struct PortSnapshot: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let processes: [SnapshotProcess]

    public init(id: UUID = UUID(), timestamp: Date = Date(), processes: [PortProcess]) {
        self.id = id
        self.timestamp = timestamp
        self.processes = processes.map { SnapshotProcess(from: $0) }
    }

    /// Lightweight, Codable version of `PortProcess` — avoids encoding transient fields.
    public struct SnapshotProcess: Codable, Identifiable, Hashable {
        public let id: String
        public let pid: Int
        public let processName: String
        public let port: Int
        public let memoryMB: Double
        public let cpuPercent: Double
        public let uptimeSeconds: Double
        public let dockerContainerName: String?

        public init(from p: PortProcess) {
            self.id                  = p.id
            self.pid                 = p.pid
            self.processName         = p.processName
            self.port                = p.port
            self.memoryMB            = p.memoryMB
            self.cpuPercent          = p.cpuPercent
            self.uptimeSeconds       = p.uptimeSeconds
            self.dockerContainerName = p.dockerContainerName
        }
    }
}
