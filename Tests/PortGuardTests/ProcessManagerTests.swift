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

    func testFetchActivePorts() {
        let processes = ProcessManager.shared.fetchActivePorts(showOnlyDev: false)
        XCTAssertNotNil(processes)
    }

    func testCustomDevKeywords() {
        let processes = ProcessManager.shared.fetchActivePorts(showOnlyDev: true, customDevKeywords: ["custom-service-test"])
        XCTAssertNotNil(processes)
    }
}
