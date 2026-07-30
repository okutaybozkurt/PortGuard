import Foundation
import PortGuard

public final class MockCommandExecutor: CommandExecutorProtocol, @unchecked Sendable {
    public var mockLsofOutput: String = ""
    public var mockPsOutput: String = ""

    /// Records every invocation so tests can assert exactly what would have hit the real shell.
    public private(set) var invocations: [(executable: String, arguments: [String])] = []

    public init(mockLsofOutput: String = "", mockPsOutput: String = "") {
        self.mockLsofOutput = mockLsofOutput
        self.mockPsOutput = mockPsOutput
    }

    public func runCommand(executable: String, arguments: [String]) -> String {
        invocations.append((executable, arguments))

        if executable.contains("lsof") {
            return mockLsofOutput
        } else if executable.contains("ps") {
            return mockPsOutput
        } else {
            return "SUCCESS"
        }
    }
}
