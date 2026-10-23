import Foundation

public protocol ProcessDetailProviding {
    func fetchDetail(pid: Int) -> ProcessDetail?
}

public protocol PortAvailabilityChecking {
    /// Portu LISTEN durumunda tutan PID'ler.
    func listeningPIDs(on port: Int) -> Set<Int>
}

public protocol ProcessLaunching {
    /// argv'yi shell string'ine birleştirmeden cwd'de ayrık başlatır. Başarıda stderr log yolunu döner.
    func launch(arguments: [String], workingDirectory: String) -> Result<String, ProcessRestartError>
}

public protocol ProcessRestarting {
    func restart(_ process: PortProcess, detail: ProcessDetail?) -> Result<Void, ProcessRestartError>
}

public enum ProcessRestartError: Error, Equatable {
    case notKillable
    case missingCommand
    case killFailed
    case portStillBusy
    /// Başlatılamadı ya da port beklenen sürede LISTEN'e geçmedi. `logPath`: stderr log dosyası.
    case launchFailed(logPath: String?)
    /// Onaydan sonra PID yeniden kullanılmış / süreç değişmiş: hiçbir şey öldürülmedi.
    case processChanged
}
