import Foundation

/// Özellik 5 — Scans a project directory to find expected port numbers from common
/// config files: `package.json`, `.env`, `docker-compose.yml`, `pubspec.yaml`, `pyproject.toml`.
public final class ProjectScanner {
    public static let shared = ProjectScanner()
    public init() {}

    // MARK: - Public

    /// Scan the given project directory and return port information found.
    /// Returns nil if no recognizable port configuration is found.
    public func scan(projectURL: URL) -> ProjectPortInfo? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: projectURL.path) else { return nil }

        // Try scanners in priority order
        let scanners: [(URL) -> ProjectPortInfo?] = [
            scanPackageJSON,
            scanEnvFile,
            scanDockerCompose,
            scanPubspec,
            scanPyproject,
            scanMakefile
        ]

        for scanner in scanners {
            if let result = scanner(projectURL) {
                return result
            }
        }

        return nil
    }

    // MARK: - Scanners

    private func scanPackageJSON(_ dir: URL) -> ProjectPortInfo? {
        let url = dir.appendingPathComponent("package.json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        var ports: Set<Int> = []

        // scripts section: look for PORT=XXXX or --port XXXX
        if let scripts = json["scripts"] as? [String: String] {
            for script in scripts.values {
                ports.formUnion(extractPortsFromString(script))
            }
        }

        // "port" top-level key (some packages expose it)
        if let portVal = json["port"] as? Int { ports.insert(portVal) }

        // Common defaults per framework
        let name = json["name"] as? String ?? dir.lastPathComponent
        let deps = mergeDeps(json)
        let defaultPort = inferDefaultPort(from: deps)
        if let dp = defaultPort { ports.insert(dp) }

        // Also check .env in same dir
        if let envPorts = readEnvFile(dir.appendingPathComponent(".env")) {
            ports.formUnion(envPorts)
        }

        return ProjectPortInfo(
            projectURL: dir,
            projectName: name,
            projectType: .node,
            expectedPorts: ports.sorted(),
            sourceFile: "package.json"
        )
    }

    private func scanEnvFile(_ dir: URL) -> ProjectPortInfo? {
        // Try .env, .env.local, .env.development
        let candidates = [".env", ".env.local", ".env.development"]
        for candidate in candidates {
            let url = dir.appendingPathComponent(candidate)
            if let ports = readEnvFile(url), !ports.isEmpty {
                return ProjectPortInfo(
                    projectURL: dir,
                    projectName: dir.lastPathComponent,
                    projectType: .generic,
                    expectedPorts: ports.sorted(),
                    sourceFile: candidate
                )
            }
        }
        return nil
    }

    private func scanDockerCompose(_ dir: URL) -> ProjectPortInfo? {
        let candidates = ["docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"]
        for candidate in candidates {
            let url = dir.appendingPathComponent(candidate)
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let ports = extractDockerComposePorts(content)
            if !ports.isEmpty {
                return ProjectPortInfo(
                    projectURL: dir,
                    projectName: dir.lastPathComponent,
                    projectType: .docker,
                    expectedPorts: ports.sorted(),
                    sourceFile: candidate
                )
            }
        }
        return nil
    }

    private func scanPubspec(_ dir: URL) -> ProjectPortInfo? {
        let url = dir.appendingPathComponent("pubspec.yaml")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        // Flutter dev server defaults to port 8080 (web) or uses VM service on random port
        // We check for explicit port in args or env
        var ports: [Int] = [8080]
        if let envPorts = readEnvFile(dir.appendingPathComponent(".env")) {
            ports.append(contentsOf: envPorts)
        }
        let name = extractYamlValue(key: "name", in: url) ?? dir.lastPathComponent

        return ProjectPortInfo(
            projectURL: dir,
            projectName: name,
            projectType: .flutter,
            expectedPorts: Array(Set(ports)).sorted(),
            sourceFile: "pubspec.yaml"
        )
    }

    private func scanPyproject(_ dir: URL) -> ProjectPortInfo? {
        let candidates = ["pyproject.toml", "setup.py", "manage.py", "app.py", "main.py"]
        for candidate in candidates {
            let url = dir.appendingPathComponent(candidate)
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let ports = extractPortsFromString(content)
            let envPorts = readEnvFile(dir.appendingPathComponent(".env")) ?? []
            let all = Set(ports).union(envPorts)
            if !all.isEmpty {
                return ProjectPortInfo(
                    projectURL: dir,
                    projectName: dir.lastPathComponent,
                    projectType: .python,
                    expectedPorts: all.sorted(),
                    sourceFile: candidate
                )
            }
        }
        // Python default
        if FileManager.default.fileExists(atPath: dir.appendingPathComponent("requirements.txt").path) {
            return ProjectPortInfo(
                projectURL: dir,
                projectName: dir.lastPathComponent,
                projectType: .python,
                expectedPorts: [8000],
                sourceFile: "requirements.txt"
            )
        }
        return nil
    }

    private func scanMakefile(_ dir: URL) -> ProjectPortInfo? {
        let url = dir.appendingPathComponent("Makefile")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let ports = extractPortsFromString(content)
        guard !ports.isEmpty else { return nil }
        return ProjectPortInfo(
            projectURL: dir,
            projectName: dir.lastPathComponent,
            projectType: .generic,
            expectedPorts: ports.sorted(),
            sourceFile: "Makefile"
        )
    }

    // MARK: - Helpers

    private func readEnvFile(_ url: URL) -> Set<Int>? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var ports = Set<Int>()
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), trimmed.contains("PORT") || trimmed.contains("port") else { continue }
            // Match PORT=3000 or PORT = 3000
            if let range = trimmed.range(of: #"=\s*(\d{2,5})"#, options: .regularExpression) {
                let match = String(trimmed[range]).filter(\.isNumber)
                if let port = Int(match), port > 1024 && port < 65535 {
                    ports.insert(port)
                }
            }
        }
        return ports.isEmpty ? nil : ports
    }

    /// Extract port numbers from arbitrary text (scripts, config files).
    private func extractPortsFromString(_ text: String) -> [Int] {
        var ports: [Int] = []
        // Match: PORT=3000, --port 8080, port: 8080, :3000
        let pattern = #"(?:PORT|port|--port)[=:\s]+(\d{2,5})"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let r = Range(match.range(at: 1), in: text), let port = Int(text[r]) {
                    if port > 1024 && port < 65535 { ports.append(port) }
                }
            }
        }
        return ports
    }

    /// Extract host:container port mappings from docker-compose content.
    private func extractDockerComposePorts(_ content: String) -> [Int] {
        var ports: [Int] = []
        // Match YAML ports entries: "- \"3000:3000\"" or "- 3000:3000" or "- 3000"
        let pattern = #"[-\s]+["']?(\d{2,5}):\d+"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let r = Range(match.range(at: 1), in: content), let port = Int(content[r]) {
                    if port > 0 && port < 65535 { ports.append(port) }
                }
            }
        }
        return ports
    }

    private func mergeDeps(_ json: [String: Any]) -> [String] {
        var all: [String] = []
        if let d = json["dependencies"] as? [String: Any] { all.append(contentsOf: d.keys) }
        if let d = json["devDependencies"] as? [String: Any] { all.append(contentsOf: d.keys) }
        return all
    }

    private func inferDefaultPort(from deps: [String]) -> Int? {
        if deps.contains("next") { return 3000 }
        if deps.contains("vite") { return 5173 }
        if deps.contains("react-scripts") { return 3000 }
        if deps.contains("vue") { return 5173 }
        if deps.contains("nuxt") { return 3000 }
        if deps.contains("express") { return 3000 }
        if deps.contains("fastify") { return 3000 }
        if deps.contains("nestjs") || deps.contains("@nestjs/core") { return 3000 }
        if deps.contains("svelte") || deps.contains("@sveltejs/kit") { return 5173 }
        return nil
    }

    private func extractYamlValue(key: String, in url: URL) -> String? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        for line in content.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("\(key):") {
                return line.components(separatedBy: ":").dropFirst().joined(separator: ":")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}
