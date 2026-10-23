import XCTest
@testable import PortGuard

final class ProcessDetailParserTests: XCTestCase {
    private let parser = ProcessDetailParser()

    func testParsePs() {
        let r = parser.parsePs("  4242 01:05:03 node /app/server.js --port 3000\n")
        XCTAssertEqual(r?.ppid, 4242)
        XCTAssertEqual(r?.elapsedSeconds, 3903)
        XCTAssertEqual(r?.command, "node /app/server.js --port 3000")
    }

    func testParsePsInvalid() {
        XCTAssertNil(parser.parsePs(""))
        XCTAssertNil(parser.parsePs("abc 00:01 node"))
        XCTAssertNil(parser.parsePs("12 00:01"))
    }

    func testParseCwd() {
        XCTAssertEqual(parser.parseCwd("p123\nfcwd\nn/Users/me/my app\n"), "/Users/me/my app")
        XCTAssertNil(parser.parseCwd("p123\n"))
    }

    func testParseFull() {
        let now = Date(timeIntervalSince1970: 10_000)
        let d = parser.parse(pid: 9, psOutput: "1 00:10 python3 -m http.server", lsofOutput: "p9\nfcwd\nn/tmp\n",
                             parentCommOutput: "/sbin/launchd\n", arguments: ["python3", "-m", "http.server"], now: now)
        XCTAssertEqual(d?.parentName, "launchd")
        XCTAssertEqual(d?.cwd, "/tmp")
        XCTAssertEqual(d?.startedAt, now.addingTimeInterval(-10))
        XCTAssertEqual(d?.isRestartable, true)
    }
}

private final class RestarterMocks: ProcessDetailProviding, ProcessKillingProtocol, PortAvailabilityChecking, ProcessLaunching {
    var events: [String] = []
    var detail: ProcessDetail?
    var freshDetail: ProcessDetail?       // verilirse restart içindeki taze fetch bunu döner
    var listening: Set<Int> = [5]         // port şu an kimde
    var busyAfterKill = 0                 // kill sonrası kaç yoklamada hâlâ dolu
    var launchOK = true
    var comesUp = true
    private var killed = false, launched = false

    func fetchDetail(pid: Int) -> ProcessDetail? {
        freshDetail ?? detail
    }
    func killProcess(pid: Int) -> Bool { events.append("kill"); killed = true; return true }
    func listeningPIDs(on port: Int) -> Set<Int> {
        events.append("check")
        if launched { return comesUp ? [99] : [] }
        if killed {
            if busyAfterKill > 0 { busyAfterKill -= 1; return listening }
            return []
        }
        return listening
    }
    func launch(arguments: [String], workingDirectory: String) -> Result<String, ProcessRestartError> {
        events.append("launch:\(arguments.joined(separator: "|"))@\(workingDirectory)")
        launched = true
        return launchOK ? .success("/tmp/log") : .failure(.launchFailed(logPath: nil))
    }
}

final class ProcessRestarterTests: XCTestCase {
    private let proc = PortProcess(pid: 5, processName: "node", user: "u", port: 3000, memoryMB: 1)
    private let t0 = Date(timeIntervalSince1970: 1000)
    private func detail(_ args: [String], start: Date? = Date(timeIntervalSince1970: 1000)) -> ProcessDetail {
        ProcessDetail(pid: 5, ppid: 1, parentName: nil, cwd: "/w", command: args.joined(separator: " "), arguments: args, startedAt: start)
    }

    private func err(_ r: Result<Void, ProcessRestartError>) -> ProcessRestartError? {
        if case .failure(let e) = r { return e }
        return nil
    }

    private func make(_ m: RestarterMocks) -> ProcessRestarter {
        ProcessRestarter(detailProvider: m, killer: m, portChecker: m, launcher: m, maxWait: 1, launchWait: 1, pollInterval: 0.25, sleep: { _ in })
    }

    func testKillWaitLaunchOrder() {
        let m = RestarterMocks(); m.detail = detail(["npm", "start"]); m.busyAfterKill = 2
        XCTAssertNil(err(make(m).restart(proc, detail: m.detail)))
        XCTAssertEqual(m.events, ["check", "kill", "check", "check", "check", "launch:npm|start@/w", "check"])
    }

    func testMissingCommandDoesNotKill() {
        let m = RestarterMocks()
        XCTAssertEqual(err(make(m).restart(proc, detail: nil)), .missingCommand)
        XCTAssertTrue(m.events.isEmpty)
    }

    func testNotKillable() {
        let m = RestarterMocks(); m.detail = detail(["a"])
        let p = PortProcess(pid: 5, processName: "x", user: "u", port: 1, memoryMB: 1, isKillable: false)
        XCTAssertEqual(err(make(m).restart(p, detail: nil)), .notKillable)
        XCTAssertTrue(m.events.isEmpty)
    }

    func testPortStaysBusyNoLaunch() {
        let m = RestarterMocks(); m.detail = detail(["a"]); m.busyAfterKill = 100
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .portStillBusy)
        XCTAssertFalse(m.events.contains { $0.hasPrefix("launch") })
    }

    func testLaunchFailure() {
        let m = RestarterMocks(); m.detail = detail(["a"]); m.launchOK = false
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .launchFailed(logPath: nil))
    }

    func testPortNeverComesUpReportsLogPath() {
        let m = RestarterMocks(); m.detail = detail(["a"]); m.comesUp = false
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .launchFailed(logPath: "/tmp/log"))
    }

    func testPidReuseDifferentArgsNoKill() {
        let m = RestarterMocks(); m.detail = detail(["node", "a.js"]); m.freshDetail = detail(["evil"])
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .processChanged)
        XCTAssertFalse(m.events.contains("kill"))
    }

    func testPidReuseDifferentStartNoKill() {
        let m = RestarterMocks(); m.detail = detail(["node"]); m.freshDetail = detail(["node"], start: t0.addingTimeInterval(60))
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .processChanged)
        XCTAssertFalse(m.events.contains("kill"))
    }

    func testNotListeningAnymoreNoKill() {
        let m = RestarterMocks(); m.detail = detail(["node"]); m.listening = [777]
        XCTAssertEqual(err(make(m).restart(proc, detail: m.detail)), .processChanged)
        XCTAssertFalse(m.events.contains("kill"))
    }

    func testSmallStartDriftIsAccepted() {
        let m = RestarterMocks(); m.detail = detail(["node"]); m.freshDetail = detail(["node"], start: t0.addingTimeInterval(1))
        XCTAssertNil(err(make(m).restart(proc, detail: m.detail)))
    }

    func testDetailServiceUsesExecutor() {
        let mock = MockCommandExecutor(mockLsofOutput: "p5\nfcwd\nn/w\n", mockPsOutput: "1 00:30 npm start", mockPsCommandOutput: "/sbin/launchd")
        let d = ProcessDetailService(executor: mock, argumentsReader: { _ in ["npm", "start"] }).fetchDetail(pid: 5)
        XCTAssertEqual(d?.command, "npm start")
        XCTAssertEqual(d?.arguments, ["npm", "start"])
        XCTAssertEqual(d?.cwd, "/w")
        XCTAssertEqual(d?.parentName, "launchd")
    }

    func testNoArgvMeansNotRestartable() {
        let mock = MockCommandExecutor(mockLsofOutput: "p5\nfcwd\nn/w\n", mockPsOutput: "1 00:30 npm start", mockPsCommandOutput: "x")
        let d = ProcessDetailService(executor: mock, argumentsReader: { _ in nil }).fetchDetail(pid: 5)
        XCTAssertEqual(d?.isRestartable, false)
    }
}

final class LaunchInjectionTests: XCTestCase {
    func testShellArgumentsKeepArgvSeparate() {
        let argv = ["node", "a;b", "$(whoami)", "with space"]
        XCTAssertEqual(DetachedShellLauncher.shellArguments(for: argv), ["-lc", "exec \"$@\"", "zsh"] + argv)
    }

    func testMetacharactersAreNotInterpretedByShell() throws {
        let argv = ["/bin/echo", "a;touch /tmp/pg_inj_marker", "$(echo pwned)", "x y", "`id`"]
        let task = DetachedShellLauncher.makeProcess(argv: argv, workingDirectory: "/tmp")
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        task.waitUntilExit()
        XCTAssertEqual(out, "a;touch /tmp/pg_inj_marker $(echo pwned) x y `id`\n")
        XCTAssertFalse(FileManager.default.fileExists(atPath: "/tmp/pg_inj_marker"))
    }

    func testParseProcArgs() {
        var buf: [UInt8] = [3, 0, 0, 0]
        buf += Array("/usr/bin/node".utf8) + [0, 0, 0]
        buf += Array("node".utf8) + [0] + Array("a b;c".utf8) + [0] + Array("$(x)".utf8) + [0]
        buf += Array("ENV=1".utf8) + [0]
        XCTAssertEqual(ProcessDetailParser().parseProcArgs(buf), ["node", "a b;c", "$(x)"])
        XCTAssertNil(ProcessDetailParser().parseProcArgs([1, 0, 0, 0]))
    }
}

final class QuickSearchLogicTests: XCTestCase {
    private let procs = [
        PortProcess(pid: 10, processName: "node", user: "u", port: 3000, memoryMB: 1),
        PortProcess(pid: 11, processName: "python3", user: "u", port: 8000, memoryMB: 1),
        PortProcess(pid: 3000, processName: "ruby", user: "u", port: 4567, memoryMB: 1),
    ]

    func testEmptyQueryReturnsAllByPort() {
        XCTAssertEqual(QuickSearchLogic.filter(procs, query: " ").map(\.port), [3000, 4567, 8000])
    }

    func testNameAndExactPortFirst() {
        XCTAssertEqual(QuickSearchLogic.filter(procs, query: "PYTH").map(\.pid), [11])
        // "3000" eşleşir: port 3000 (tam) ve pid 3000 (ruby)
        XCTAssertEqual(QuickSearchLogic.filter(procs, query: "3000").map(\.pid), [10, 3000])
    }

    func testFreePort() {
        XCTAssertEqual(QuickSearchLogic.freePort(for: "9000", in: procs), 9000)
        XCTAssertNil(QuickSearchLogic.freePort(for: "3000", in: procs))
        XCTAssertNil(QuickSearchLogic.freePort(for: "node", in: procs))
        XCTAssertNil(QuickSearchLogic.freePort(for: "99999", in: procs))
    }

    func testSelectionByIdFallsBackToFirst() {
        let r = QuickSearchLogic.filter(procs, query: "")
        XCTAssertEqual(QuickSearchLogic.selectionIndex(id: r[1].id, in: r), 1)
        XCTAssertEqual(QuickSearchLogic.selectionIndex(id: "gone", in: r), 0)
        XCTAssertEqual(QuickSearchLogic.selectionIndex(id: nil, in: r), 0)
    }

    func testIsStillActive() {
        XCTAssertTrue(QuickSearchLogic.isStillActive(procs[0], in: procs))
        let reused = PortProcess(pid: 10, processName: "x", user: "u", port: 9999, memoryMB: 1)
        XCTAssertFalse(QuickSearchLogic.isStillActive(reused, in: procs))
    }

    func testClampedSelection() {
        XCTAssertEqual(QuickSearchLogic.clampedSelection(5, count: 3), 2)
        XCTAssertEqual(QuickSearchLogic.clampedSelection(-1, count: 3), 0)
        XCTAssertEqual(QuickSearchLogic.clampedSelection(1, count: 0), 0)
    }
}
