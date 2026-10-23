import Foundation

/// "Durdur ve yeniden başlat": doğrula → SIGTERM → port boşalana kadar yokla → argv'yi başlat → port LISTEN'e geçene kadar bekle.
/// Komut satırı sır içerebilir; bu sınıf hiçbir yere loglamaz.
public final class ProcessRestarter: ProcessRestarting {
    private let detailProvider: ProcessDetailProviding
    private let killer: ProcessKillingProtocol
    private let portChecker: PortAvailabilityChecking
    private let launcher: ProcessLaunching
    private let sleep: (TimeInterval) -> Void
    private let maxWait: TimeInterval
    private let launchWait: TimeInterval
    private let pollInterval: TimeInterval
    private let startTolerance: TimeInterval

    public init(
        detailProvider: ProcessDetailProviding,
        killer: ProcessKillingProtocol,
        portChecker: PortAvailabilityChecking,
        launcher: ProcessLaunching = DetachedShellLauncher(),
        maxWait: TimeInterval = 3.0,
        launchWait: TimeInterval = 8.0,
        pollInterval: TimeInterval = 0.25,
        startTolerance: TimeInterval = 1.5,
        sleep: @escaping (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    ) {
        self.detailProvider = detailProvider
        self.killer = killer
        self.portChecker = portChecker
        self.launcher = launcher
        self.maxWait = maxWait
        self.launchWait = launchWait
        self.pollInterval = pollInterval
        self.startTolerance = startTolerance
        self.sleep = sleep
    }

    /// Bloklar (kill bekleme + launch bekleme); arka plan thread'inden çağrılmalı.
    /// `detail`: kullanıcının onayladığı detay; kill'den hemen önce yeniden çekilip eşleşmesi doğrulanır.
    public func restart(_ process: PortProcess, detail: ProcessDetail? = nil) -> Result<Void, ProcessRestartError> {
        guard process.isKillable else { return .failure(.notKillable) }

        // PID yeniden kullanımına karşı: kill'den hemen önce taze detay.
        guard let fresh = detailProvider.fetchDetail(pid: process.pid), fresh.isRestartable,
              let cwd = fresh.cwd else { return .failure(.missingCommand) }
        if let confirmed = detail {
            guard confirmed.arguments == fresh.arguments, sameStart(confirmed.startedAt, fresh.startedAt) else {
                return .failure(.processChanged)
            }
        }
        guard portChecker.listeningPIDs(on: process.port).contains(process.pid) else {
            return .failure(.processChanged)
        }

        guard killer.killProcess(pid: process.pid) else { return .failure(.killFailed) }

        var waited: TimeInterval = 0
        while !portChecker.listeningPIDs(on: process.port).isEmpty {
            if waited >= maxWait { return .failure(.portStillBusy) }
            sleep(pollInterval)
            waited += pollInterval
        }

        let logPath: String
        switch launcher.launch(arguments: fresh.arguments, workingDirectory: cwd) {
        case .success(let path): logPath = path
        case .failure(let e): return .failure(e)
        }

        waited = 0
        while portChecker.listeningPIDs(on: process.port).isEmpty {
            if waited >= launchWait { return .failure(.launchFailed(logPath: logPath)) }
            sleep(pollInterval)
            waited += pollInterval
        }
        return .success(())
    }

    private func sameStart(_ a: Date?, _ b: Date?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x?, y?): return abs(x.timeIntervalSince(y)) <= startTolerance
        default: return false
        }
    }
}
