import Foundation

/// Docker container information fetched via `docker ps`.
public struct DockerContainer: Identifiable, Hashable, Equatable {
    public let id: String          // short container ID
    public let name: String        // container name (e.g. "my-postgres")
    public let image: String       // image name (e.g. "postgres:15")
    public let status: String      // "Up 2 hours", "Exited (0) 5 minutes ago"
    public let ports: [PortMapping]

    public struct PortMapping: Hashable, Equatable {
        public let hostPort: Int
        public let containerPort: Int
        public let protocol_: String  // "tcp" or "udp"

        public init(hostPort: Int, containerPort: Int, protocol_: String = "tcp") {
            self.hostPort      = hostPort
            self.containerPort = containerPort
            self.protocol_     = protocol_
        }
    }

    public init(id: String, name: String, image: String, status: String, ports: [PortMapping]) {
        self.id     = id
        self.name   = name
        self.image  = image
        self.status = status
        self.ports  = ports
    }

    /// Host-side ports this container exposes
    public var hostPorts: [Int] { ports.map(\.hostPort) }

    public var isRunning: Bool { status.lowercased().hasPrefix("up") }
}
