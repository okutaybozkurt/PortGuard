import XCTest
@testable import PortGuard

final class ProcessManagerTests: XCTestCase {

    func testPortProcessMemoryFormatting() {
        let smallProc = PortProcess(pid: 100, processName: "node", user: "dev", port: 3000, memoryMB: 450.5, isDevProcess: true)
        XCTAssertEqual(smallProc.formattedMemory, "450.5 MB")

        let largeProc = PortProcess(pid: 200, processName: "java", user: "dev", port: 8080, memoryMB: 2560.0, isDevProcess: true)
        XCTAssertEqual(largeProc.formattedMemory, "2.50 GB")
    }

    func testFetchActivePorts() {
        let processes = ProcessManager.shared.fetchActivePorts(showOnlyDev: false)
        XCTAssertNotNil(processes)
        // Should execute lsof without crash
    }
}
