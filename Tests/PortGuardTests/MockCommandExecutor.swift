import Foundation
import PortGuard

public final class MockCommandExecutor: CommandExecutorProtocol, @unchecked Sendable {
    public var mockLsofOutput: String = ""
    public var mockPsOutput: String = ""
    public var mockPsCommandOutput: String = ""

    /// Records every invocation so tests can assert exactly what would have hit the real shell.
    public private(set) var invocations: [(executable: String, arguments: [String])] = []

    public init(mockLsofOutput: String = "", mockPsOutput: String = "", mockPsCommandOutput: String = "") {
        self.mockLsofOutput = mockLsofOutput
        self.mockPsOutput = mockPsOutput
        self.mockPsCommandOutput = mockPsCommandOutput
    }

    public func runCommand(executable: String, arguments: [String]) -> String {
        invocations.append((executable, arguments))

        if executable.contains("lsof") {
            return mockLsofOutput
        } else if executable.contains("ps") {
            // ProcessManager makes two distinct `ps` calls: one for %cpu/rss/etime metrics,
            // one for the untruncated command name (`comm=`). Route by the requested fields
            // so each test's mocked output lands on the call it's meant for.
            if arguments.contains(where: { $0.contains("comm=") }) {
                return mockPsCommandOutput
            }
            return mockPsOutput
        } else {
            return "SUCCESS"
        }
    }
}
