import Foundation
import PortGuard

public final class MockCommandExecutor: CommandExecutorProtocol, @unchecked Sendable {
    public var mockLsofOutput: String = ""
    public var mockPsOutput: String = ""

    public init(mockLsofOutput: String = "", mockPsOutput: String = "") {
        self.mockLsofOutput = mockLsofOutput
        self.mockPsOutput = mockPsOutput
    }

    public func runCommand(executable: String, arguments: [String]) -> String {
        if executable.contains("lsof") {
            return mockLsofOutput
        } else if executable.contains("ps") {
            return mockPsOutput
        } else {
            return "SUCCESS"
        }
    }
}
