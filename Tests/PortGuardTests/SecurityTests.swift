import XCTest
@testable import PortGuard

/// Guards the invariants that keep PortGuard safe to run with a user's real dev processes:
/// no shell injection, no PATH-hijackable executables, and no privileged system process
/// can be relabeled as "safe to kill" through user-supplied input.
final class SecurityTests: XCTestCase {

    // MARK: - Command execution safety

    func testKillProcessUsesAbsolutePathAndOnlyNumericPIDArgument() {
        let executor = MockCommandExecutor()
        let manager = ProcessManager(commandExecutor: executor)

        _ = manager.killProcess(pid: 48291)

        XCTAssertEqual(executor.invocations.count, 1)
        let call = executor.invocations[0]

        // Absolute path only — never resolved via $PATH, which a malicious dir entry could hijack.
        XCTAssertEqual(call.executable, "/bin/kill")

        // Exactly ["-9", "<pid>"] — no extra flags, no shell metacharacters, no string concatenation.
        XCTAssertEqual(call.arguments, ["-9", "48291"])
        XCTAssertFalse(call.arguments.contains { $0.contains(";") || $0.contains("|") || $0.contains("&") })
    }

    func testKillProcessArgumentIsDerivedFromTypedIntNotRawString() {
        // pid is typed as Int at the call site, so there is no code path through which a
        // string like "1; rm -rf /" could ever reach the argument array — this test documents
        // that invariant so a future refactor to a String-based PID can't silently reopen it.
        let executor = MockCommandExecutor()
        let manager = ProcessManager(commandExecutor: executor)

        _ = manager.killProcess(pid: -1) // even a nonsensical PID stays a plain numeric string
        XCTAssertEqual(executor.invocations.last?.arguments, ["-9", "-1"])
    }

    func testFetchActivePortsUsesAbsolutePathsForLsofAndPs() {
        let executor = MockCommandExecutor(mockLsofOutput: "", mockPsOutput: "")
        let manager = ProcessManager(commandExecutor: executor)

        _ = manager.fetchActivePorts(showOnlyDev: false)

        let executables = executor.invocations.map { $0.executable }
        XCTAssertTrue(executables.contains("/usr/sbin/lsof"))
        XCTAssertTrue(executables.contains("/bin/ps"))
        XCTAssertFalse(executables.contains("lsof")) // bare command name would be PATH-resolved
        XCTAssertFalse(executables.contains("ps"))
    }

    // MARK: - Filter integrity: user input can't unmask system-critical processes

    func testSystemBlacklistCannotBeOverriddenByCustomKeyword() {
        // A user typing "launchd" into the custom keyword field (by mistake or otherwise)
        // must not cause PortGuard to present a core system daemon as a killable dev process.
        let filter = DevProcessFilter(customKeywords: ["launchd", "controlcenter"])

        XCTAssertFalse(filter.isDevProcess(command: "launchd"))
        XCTAssertFalse(filter.isDevProcess(command: "ControlCenter"))
    }

    func testCustomKeywordsAreCaseInsensitiveAndTrimmed() {
        let filter = DevProcessFilter(customKeywords: ["  My-Weird-Service  ", "", "   "])
        XCTAssertTrue(filter.isDevProcess(command: "my-weird-service-worker"))
    }

    // MARK: - Parser robustness against malformed / adversarial lsof output

    func testParserIgnoresTruncatedAndMalformedLines() {
        let malformed = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        node    48291 orhan   23u  IPv4 0x123      0t0  TCP *:3000 (LISTEN)
        not-enough-columns
        node    notapid orhan   23u  IPv4 0x123    0t0  TCP *:4000 (LISTEN)
        node    48292 orhan   23u  IPv4 0x123      0t0  TCP *:notaport (LISTEN)
        """
        let executor = MockCommandExecutor(mockLsofOutput: malformed, mockPsOutput: "48291 1.0 1024")
        let manager = ProcessManager(commandExecutor: executor)

        let result = manager.fetchActivePorts(showOnlyDev: true)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 3000)
    }

    func testParserDeduplicatesRepeatedPidPortPairs() {
        let duplicated = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        node    48291 orhan   23u  IPv4 0x123      0t0  TCP *:3000 (LISTEN)
        node    48291 orhan   24u  IPv6 0x124      0t0  TCP *:3000 (LISTEN)
        """
        let executor = MockCommandExecutor(mockLsofOutput: duplicated, mockPsOutput: "48291 1.0 1024")
        let manager = ProcessManager(commandExecutor: executor)

        let result = manager.fetchActivePorts(showOnlyDev: true)
        XCTAssertEqual(result.count, 1)
    }

    func testParserHandlesIPv6AddressNotation() {
        let ipv6 = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        postgres 909 orhan   23u  IPv6 0x123      0t0  TCP [::1]:5432 (LISTEN)
        """
        let executor = MockCommandExecutor(mockLsofOutput: ipv6, mockPsOutput: "909 0.5 2048")
        let manager = ProcessManager(commandExecutor: executor)

        let result = manager.fetchActivePorts(showOnlyDev: true)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 5432)
    }
}
