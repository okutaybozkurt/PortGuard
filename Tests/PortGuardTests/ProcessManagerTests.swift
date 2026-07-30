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

    func testMockProcessParsingAndFiltering() {
        let mockLsof = """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        node    48291 orhan   23u  IPv4 0x123      0t0  TCP *:3000 (LISTEN)
        rapportd  432 orhan    4u  IPv4 0x124      0t0  TCP *:49152 (LISTEN)
        python3 51203 orhan    3u  IPv6 0x125      0t0  TCP *:8000 (LISTEN)
        """

        let mockPs = """
        48291  12.5 1048576
        51203   3.2  524288
          432   0.1  102400
        """

        let executor = MockCommandExecutor(mockLsofOutput: mockLsof, mockPsOutput: mockPs)
        let manager = ProcessManager(commandExecutor: executor)

        let devOnly = manager.fetchActivePorts(showOnlyDev: true)
        XCTAssertEqual(devOnly.count, 2)
        XCTAssertEqual(devOnly[0].port, 3000)
        XCTAssertEqual(devOnly[0].processName, "node")
        XCTAssertEqual(devOnly[0].memoryMB, 1024.0) // 1048576 KB / 1024 = 1024 MB
        XCTAssertEqual(devOnly[0].formattedMemory, "1.00 GB")

        XCTAssertEqual(devOnly[1].port, 8000)
        XCTAssertEqual(devOnly[1].processName, "python3")
        XCTAssertEqual(devOnly[1].memoryMB, 512.0)

        let allPorts = manager.fetchActivePorts(showOnlyDev: false)
        XCTAssertEqual(allPorts.count, 3)
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
