import Foundation

/// Fetches Docker container information using the `docker` CLI.
/// If Docker is not installed or not running, all methods return empty results silently.
public final class DockerService {
    public static let shared = DockerService()

    private let executor: CommandExecutorProtocol
    private let dockerPaths = [
        "/usr/local/bin/docker",
        "/opt/homebrew/bin/docker",
        "/usr/bin/docker"
    ]

    public init(executor: CommandExecutorProtocol = ShellCommandExecutor()) {
        self.executor = executor
    }

    // MARK: - Public

    /// Returns true if `docker` binary is accessible and the Docker daemon is running.
    public func isDockerAvailable() -> Bool {
        guard let dockerPath = resolvedDockerPath() else { return false }
        let output = executor.runCommand(executable: dockerPath, arguments: ["info", "--format", "{{.ServerVersion}}"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Fetches running containers via `docker ps`.
    /// Returns empty array if Docker is unavailable.
    public func fetchRunningContainers() -> [DockerContainer] {
        guard let dockerPath = resolvedDockerPath() else { return [] }

        // format: ID|Name|Image|Status|Ports (one container per line)
        let format = "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}"
        let output = executor.runCommand(
            executable: dockerPath,
            arguments: ["ps", "--format", format]
        )

        return parseDockerPsOutput(output)
    }

    /// Build a lookup: hostPort → DockerContainer.
    /// Useful for enriching `PortProcess` objects.
    public func buildPortToContainerMap() -> [Int: DockerContainer] {
        var map: [Int: DockerContainer] = [:]
        for container in fetchRunningContainers() {
            for port in container.hostPorts {
                map[port] = container
            }
        }
        return map
    }

    // MARK: - Private

    private func resolvedDockerPath() -> String? {
        dockerPaths.first { FileManager.default.fileExists(atPath: $0) }
    }

    private func parseDockerPsOutput(_ raw: String) -> [DockerContainer] {
        raw
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .compactMap { parseLine($0) }
    }

    /// Parses one line of `docker ps --format "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}"` output.
    private func parseLine(_ line: String) -> DockerContainer? {
        let parts = line.components(separatedBy: "|")
        guard parts.count >= 5 else { return nil }

        let id     = parts[0].trimmingCharacters(in: .whitespaces)
        let name   = parts[1].trimmingCharacters(in: .whitespaces)
        let image  = parts[2].trimmingCharacters(in: .whitespaces)
        let status = parts[3].trimmingCharacters(in: .whitespaces)
        let rawPorts = parts[4...].joined(separator: "|") // ports may contain | in edge cases

        let mappings = parsePortMappings(rawPorts)

        return DockerContainer(id: id, name: name, image: image, status: status, ports: mappings)
    }

    /// Parse Docker port strings like:
    ///   "0.0.0.0:5432->5432/tcp, 0.0.0.0:8080->80/tcp"
    private func parsePortMappings(_ raw: String) -> [DockerContainer.PortMapping] {
        raw
            .components(separatedBy: ",")
            .compactMap { segment -> DockerContainer.PortMapping? in
                let s = segment.trimmingCharacters(in: .whitespaces)
                // Expect: "0.0.0.0:5432->5432/tcp"
                guard s.contains("->") else { return nil }

                let sides = s.components(separatedBy: "->")
                guard sides.count == 2 else { return nil }

                // Left: host side "0.0.0.0:5432" or ":::5432"
                let hostStr = sides[0]
                guard let hostPort = Int(hostStr.components(separatedBy: ":").last ?? "") else { return nil }

                // Right: container side "5432/tcp"
                let rightParts = sides[1].components(separatedBy: "/")
                guard let containerPort = Int(rightParts[0]) else { return nil }
                let proto = rightParts.count > 1 ? rightParts[1] : "tcp"

                return DockerContainer.PortMapping(
                    hostPort: hostPort,
                    containerPort: containerPort,
                    protocol_: proto
                )
            }
    }
}
