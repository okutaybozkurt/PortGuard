import XCTest
@testable import PortGuard

final class ProcessManagerTests: XCTestCase {

    func testPortProcessMemoryFormatting() {
        let smallProc = PortProcess(pid: 100, processName: "node", user: "dev", port: 3000, memoryMB: 450.5, cpuPercent: 4.2, isDevProcess: true)
        XCTAssertEqual(smallProc.formattedMemory, "450.5 MB")
        XCTAssertEqual(smallProc.formattedCPU, "4.2%")

        let largeProc = PortProcess(pid: 200, processName: "java", user: "dev", port: 8080, memoryMB: 2560.0, cpuPercent: 18.7, isDevProcess: true)
        XCTAssertEqual(largeProc.formattedMemory, "2.50 GB")
        XCTAssertEqual(largeProc.formattedCPU, "18.7%")
    }

    func testPortProcessUptimeFormatting() {
        let freshProc = PortProcess(pid: 1, processName: "node", user: "dev", port: 3000, memoryMB: 10, uptimeSeconds: 90)
        XCTAssertEqual(freshProc.formattedUptime, "1dk")
        XCTAssertFalse(freshProc.isLongRunning)

        let hoursProc = PortProcess(pid: 2, processName: "node", user: "dev", port: 3001, memoryMB: 10, uptimeSeconds: 3 * 3600 + 25 * 60)
        XCTAssertEqual(hoursProc.formattedUptime, "3s 25dk")
        XCTAssertFalse(hoursProc.isLongRunning)

        let daysProc = PortProcess(pid: 3, processName: "node", user: "dev", port: 3002, memoryMB: 10, uptimeSeconds: 2 * 86_400 + 3600)
        XCTAssertEqual(daysProc.formattedUptime, "2g 1s")
        XCTAssertTrue(daysProc.isLongRunning)
    }

    func testMockProcessParsingAndFiltering() {
        let mockLsof = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        node    48291 orhan   23u  IPv4 0x123      0t0  TCP *:3000 (LISTEN)
        rapportd  432 orhan    4u  IPv4 0x124      0t0  TCP *:49152 (LISTEN)
        spotify  1000 orhan   10u  IPv4 0x126      0t0  TCP *:7768 (LISTEN)
        python3 51203 orhan    3u  IPv6 0x125      0t0  TCP *:8000 (LISTEN)
        """

        let mockPs = """
        48291  12.5 1048576 3-01:05:09
        51203   3.2  524288 00:45
          432   0.1  102400 10:12:00
         1000   1.5  300000 00:10
        """

        let executor = MockCommandExecutor(mockLsofOutput: mockLsof, mockPsOutput: mockPs)
        let manager = ProcessManager(commandExecutor: executor)

        let devOnly = manager.fetchActivePorts(showOnlyDev: true)
        XCTAssertEqual(devOnly.count, 2)
        XCTAssertEqual(devOnly[0].port, 3000)
        XCTAssertEqual(devOnly[0].processName, "node")
        XCTAssertEqual(devOnly[0].memoryMB, 1024.0) // 1048576 KB / 1024 = 1024 MB
        XCTAssertEqual(devOnly[0].formattedMemory, "1.00 GB")
        let expectedUptime: Double = 263109  // 3 * 86_400 + 3_600 + 5 * 60 + 9
        XCTAssertEqual(devOnly[0].uptimeSeconds, expectedUptime)
        XCTAssertTrue(devOnly[0].isLongRunning)

        XCTAssertEqual(devOnly[1].port, 8000)
        XCTAssertEqual(devOnly[1].processName, "python3")
        XCTAssertEqual(devOnly[1].memoryMB, 512.0)
        XCTAssertEqual(devOnly[1].uptimeSeconds, 45)
        XCTAssertFalse(devOnly[1].isLongRunning)

        // When showOnlyDev is false, rapportd is STILL dropped (isSystemProcess),
        // but spotify is shown (it's not dev, but not a system process)
        let allPorts = manager.fetchActivePorts(showOnlyDev: false)
        XCTAssertEqual(allPorts.count, 3)
        XCTAssertTrue(allPorts.contains(where: { $0.processName == "spotify" }))
        XCTAssertFalse(allPorts.contains(where: { $0.processName == "rapportd" }))
    }

    func testCustomDevKeywordsStrategy() {
        let mockLsof = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        my-service 777 orhan 10u  IPv4 0x111      0t0  TCP *:9000 (LISTEN)
        """
        let mockPs = " 777   1.0  204800"

        let executor = MockCommandExecutor(mockLsofOutput: mockLsof, mockPsOutput: mockPs)
        let manager = ProcessManager(commandExecutor: executor)

        let filteredNoCustom = manager.fetchActivePorts(showOnlyDev: true, customDevKeywords: [])
        XCTAssertEqual(filteredNoCustom.count, 0)

        let filteredWithCustom = manager.fetchActivePorts(showOnlyDev: true, customDevKeywords: ["my-service"])
        XCTAssertEqual(filteredWithCustom.count, 1)
        XCTAssertEqual(filteredWithCustom[0].port, 9000)
    }
}
