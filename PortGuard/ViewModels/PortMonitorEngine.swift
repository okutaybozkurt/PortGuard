import Foundation
import Combine
import SwiftUI
import AppKit

public enum SortOption: String, CaseIterable, Identifiable {
    case memoryDescending = "RAM (Yüksek > Düşük)"
    case memoryAscending  = "RAM (Düşük > Yüksek)"
    case cpuDescending    = "CPU (Yüksek > Düşük)"
    case portAscending    = "Port (Küçük > Büyük)"
    case processName      = "Süreç Adı"

    public var id: String { rawValue }
}

/// App ve AppDelegate'in aynı engine örneğini paylaşması için köprü.
public enum AppEngineHolder {
    public static let engine = PortMonitorEngine()
}

public final class PortMonitorEngine: ObservableObject {

    // MARK: - Mevcut Published Vars

    @Published public var activeProcesses: [PortProcess] = []
    @Published public var searchText: String = ""
    @Published public var sortOption: SortOption = .memoryDescending
    @Published public var filterDevOnly: Bool = UserDefaults.standard.object(forKey: "filterDevOnly") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(filterDevOnly, forKey: "filterDevOnly")
            refreshData()
        }
    }
    @Published public var refreshInterval: Double = UserDefaults.standard.object(forKey: "refreshInterval") as? Double ?? 5.0 {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            restartTimer()
        }
    }
    @Published public var memoryAlertThresholdMB: Double = UserDefaults.standard.object(forKey: "memoryAlertThresholdMB") as? Double ?? 1024.0 {
        didSet {
            UserDefaults.standard.set(memoryAlertThresholdMB, forKey: "memoryAlertThresholdMB")
        }
    }
    @Published public var notificationsEnabled: Bool = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    @Published public var showInDock: Bool = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            updateActivationPolicy()
        }
    }
    @Published public var customDevKeywordsInput: String = UserDefaults.standard.string(forKey: "customDevKeywordsInput") ?? "" {
        didSet {
            UserDefaults.standard.set(customDevKeywordsInput, forKey: "customDevKeywordsInput")
            refreshData()
        }
    }
    @Published public var selectedTheme: AppTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "") ?? .system {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    @Published public var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr" {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "appLanguage")
        }
    }
    @Published public var lastUpdated: Date = Date()
    @Published public var isRefreshing: Bool = false

    // MARK: - Özellik 1: Network Activity (ESTABLISHED)

    @Published public var networkConnections: [NetworkConnection] = []

    // MARK: - Özellik 2: Pinned Ports

    @Published public var pinnedPorts: Set<Int> = {
        let saved = UserDefaults.standard.array(forKey: "pinnedPorts") as? [Int] ?? []
        return Set(saved)
    }() {
        didSet {
            UserDefaults.standard.set(Array(pinnedPorts), forKey: "pinnedPorts")
        }
    }

    /// Pinned ports that are NOT currently active (ghost rows)
    public var ghostPinnedPorts: [Int] {
        let activePorts = Set(activeProcesses.map(\.port))
        return pinnedPorts.subtracting(activePorts).sorted()
    }

    public func togglePin(port: Int) {
        if pinnedPorts.contains(port) {
            pinnedPorts.remove(port)
        } else {
            pinnedPorts.insert(port)
        }
    }

    // MARK: - Özellik 4: Conflict Predictor

    /// If searchText is a port number, returns the process occupying that port (if any).
    public var portConflictProcess: PortProcess? {
        guard let port = Int(searchText.trimmingCharacters(in: .whitespaces)),
              port > 0 && port < 65535 else { return nil }
        return activeProcesses.first(where: { $0.port == port })
    }

    /// True when searchText looks like a port number
    public var searchIsPortQuery: Bool {
        Int(searchText.trimmingCharacters(in: .whitespaces)) != nil
    }

    // MARK: - Özellik 5: Project Scanner

    @Published public var scannedProject: ProjectPortInfo? = nil

    /// Scan a project directory asynchronously.
    public func scanProject(at url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = ProjectScanner.shared.scan(projectURL: url)
            DispatchQueue.main.async {
                self?.scannedProject = result
            }
        }
    }

    public func clearScannedProject() {
        scannedProject = nil
    }

    /// Ports expected by the scanned project that are NOT currently active.
    public var missingProjectPorts: [Int] {
        guard let project = scannedProject else { return [] }
        let activePorts = Set(activeProcesses.map(\.port))
        return project.expectedPorts.filter { !activePorts.contains($0) }
    }

    /// Ports expected by the scanned project that ARE currently active.
    public var matchingProjectPorts: [PortProcess] {
        guard let project = scannedProject else { return [] }
        let expected = Set(project.expectedPorts)
        return activeProcesses.filter { expected.contains($0.port) }
    }

    // MARK: - Özellik 6: History

    private let historyStore = HistoryStore.shared

    @Published public var recentHistory: [Date: [PortSnapshot]] = [:]
    @Published public var historyDaysToShow: Int = 7

    public func loadHistory() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let history = self.historyStore.loadRecent(days: self.historyDaysToShow)
            DispatchQueue.main.async { self.recentHistory = history }
        }
    }

    public func clearHistory() {
        historyStore.purgeOlderThan(days: 0)
        recentHistory = [:]
    }

    // MARK: - Özellik 8: Rule Engine

    @Published public var policyRules: [PolicyRule] = [] {
        didSet { RuleEngine.shared.saveRules(policyRules) }
    }
    @Published public var activeViolations: [RuleViolation] = []

    public func addRule(_ rule: PolicyRule) {
        policyRules.append(rule)
    }

    public func removeRule(at offsets: IndexSet) {
        policyRules.remove(atOffsets: offsets)
    }

    public func updateRule(_ rule: PolicyRule) {
        if let idx = policyRules.firstIndex(where: { $0.id == rule.id }) {
            policyRules[idx] = rule
        }
    }

    private func evaluateRules(processes: [PortProcess]) {
        let violations = RuleEngine.shared.evaluate(processes: processes, rules: policyRules)
        DispatchQueue.main.async { [weak self] in
            self?.activeViolations = violations
        }

        // Auto-kill if rule action requires it
        for violation in violations where violation.rule.action == .kill || violation.rule.action == .alertKill {
            guard violation.process.isKillable else { continue }
            _ = processService.killProcess(pid: violation.process.pid)
        }

        // Notify for alert violations
        if notificationsEnabled {
            for violation in violations where violation.rule.action == .alert || violation.rule.action == .alertKill {
                notificationService.notify(
                    title: "PortGuard — Kural İhlali",
                    body: violation.description
                )
            }
        }
    }

    // MARK: - Computed Properties

    public var customKeywordsList: [String] {
        customDevKeywordsInput
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public var filteredProcesses: [PortProcess] {
        var result = activeProcesses

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { proc in
                proc.processName.lowercased().contains(query) ||
                "\(proc.port)".contains(query) ||
                "\(proc.pid)".contains(query) ||
                proc.user.lowercased().contains(query)
            }
        }

        // Özellik 2: Pinned ports come first, then apply sort
        result.sort { a, b in
            let aPinned = pinnedPorts.contains(a.port)
            let bPinned = pinnedPorts.contains(b.port)
            if aPinned != bPinned { return aPinned }

            switch sortOption {
            case .memoryDescending: return a.memoryMB > b.memoryMB
            case .memoryAscending:  return a.memoryMB < b.memoryMB
            case .cpuDescending:    return a.cpuPercent > b.cpuPercent
            case .portAscending:    return a.port < b.port
            case .processName:      return a.processName.lowercased() < b.processName.lowercased()
            }
        }

        return result
    }

    public var totalMemoryMB: Double {
        activeProcesses.reduce(0.0) { $0 + $1.memoryMB }
    }

    public var formattedTotalMemory: String {
        let total = totalMemoryMB
        if total >= 1024 {
            return String(format: "%.2f GB", total / 1024.0)
        } else {
            return String(format: "%.1f MB", total)
        }
    }

    public var highestMemoryProcess: PortProcess? {
        activeProcesses.max(by: { $0.memoryMB < $1.memoryMB })
    }

    // MARK: - Private State

    private var timer: Timer?
    private let processService: ProcessServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let detailProvider: ProcessDetailProviding
    private let restarter: ProcessRestarting

    // MARK: - Init

    public init(
        processService: ProcessServiceProtocol = ProcessManager.shared,
        notificationService: NotificationServiceProtocol = NotificationManager.shared,
        detailProvider: ProcessDetailProviding? = nil,
        restarter: ProcessRestarting? = nil
    ) {
        self.processService = processService
        self.notificationService = notificationService
        let detailService = ProcessDetailService()
        let provider = detailProvider ?? detailService
        self.detailProvider = provider
        self.restarter = restarter ?? ProcessRestarter(
            detailProvider: provider,
            killer: processService,
            portChecker: detailService
        )

        self.policyRules = RuleEngine.shared.loadRules()
        self.notificationService.requestAuthorization()
        refreshData()
        startTimer()
    }

    deinit {
        stopTimer()
    }

    // MARK: - Refresh

    public func refreshData() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let keywords = self.customKeywordsList
            let processes = self.processService.fetchActivePorts(
                showOnlyDev: self.filterDevOnly,
                customDevKeywords: keywords
            )

            // Özellik 1: ESTABLISHED connections (only when using real ProcessManager)
            let connections: [NetworkConnection]
            if let pm = self.processService as? ProcessManager {
                connections = pm.fetchEstablishedConnections()
            } else {
                connections = []
            }

            // Özellik 6: Persist snapshot to history
            let snapshot = PortSnapshot(processes: processes)
            self.historyStore.append(snapshot: snapshot)

            DispatchQueue.main.async {
                self.activeProcesses = processes
                self.networkConnections = connections
                self.lastUpdated = Date()

                if self.notificationsEnabled {
                    self.notificationService.checkAndNotifyHighMemory(
                        processes: processes,
                        thresholdMB: self.memoryAlertThresholdMB
                    )
                }

                // Özellik 8: Evaluate rules after each refresh
                self.evaluateRules(processes: processes)
            }
        }
    }

    // MARK: - Kill

    public func killProcess(_ process: PortProcess) {
        // Second guard beyond the UI hiding the kill button — a shared proxy process
        // (e.g. Docker Desktop's com.docker.backend) must never be killable from any code path.
        guard process.isKillable else { return }

        let success = processService.killProcess(pid: process.pid)
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.activeProcesses.removeAll { $0.pid == process.pid }
                self?.refreshData()
            }
        }
    }

    // MARK: - Detail / Restart

    /// Süreç detayını arka planda alır; `completion` ana thread'de çağrılır.
    public func fetchDetail(for process: PortProcess, completion: @escaping (ProcessDetail?) -> Void) {
        let provider = detailProvider
        DispatchQueue.global(qos: .userInitiated).async {
            let detail = provider.fetchDetail(pid: process.pid)
            DispatchQueue.main.async { completion(detail) }
        }
    }

    /// Durdur ve yeniden başlat (onay alınmış varsayılır). Arka planda çalışır; sonuç ana thread'de döner.
    public func restartProcess(_ process: PortProcess, detail: ProcessDetail? = nil,
                               completion: ((Result<Void, ProcessRestartError>) -> Void)? = nil) {
        guard process.isKillable else { completion?(.failure(.notKillable)); return }
        let restarter = self.restarter
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = restarter.restart(process, detail: detail)
            DispatchQueue.main.async {
                self?.refreshData()
                completion?(result)
            }
        }
    }

    /// Detayı alır, komut + dizini NSAlert ile gösterip onay ister, onaylanırsa yeniden başlatır.
    public func requestRestart(_ process: PortProcess, language: String) {
        fetchDetail(for: process) { [weak self] detail in
            guard let self = self else { return }
            guard let detail = detail, detail.isRestartable else {
                Self.showAlert(title: "Yeniden başlatılamadı".localized(language: language),
                               message: "Komut veya çalışma dizini alınamadı.".localized(language: language),
                               language: language, confirm: false)
                return
            }
            let message = "\("Komut".localized(language: language)):\n\(detail.arguments.joined(separator: " "))\n\n\("Dizin".localized(language: language)):\n\(detail.cwd ?? "")"
            guard Self.showAlert(title: "Durdur ve Yeniden Başlat".localized(language: language),
                                 message: message, language: language, confirm: true) else { return }
            self.restartProcess(process, detail: detail) { result in
                guard case .failure(let error) = result else { return }
                var text: String
                switch error {
                case .processChanged:
                    text = "Süreç onaydan sonra değişti; hiçbir şey durdurulmadı.".localized(language: language)
                case .launchFailed(let path):
                    text = "Süreç durduruldu ancak yeni süreç portu dinlemeye başlamadı.".localized(language: language)
                    if let path = path { text += "\n\("Hata günlüğü".localized(language: language)): \(path)" }
                default:
                    text = "Süreç durdurulamadı, port boşalmadı veya komut başlatılamadı.".localized(language: language)
                }
                Self.showAlert(title: "Yeniden başlatılamadı".localized(language: language),
                               message: text, language: language, confirm: false)
            }
        }
    }

    @discardableResult
    private static func showAlert(title: String, message: String, language: String, confirm: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = confirm ? .warning : .informational
        alert.addButton(withTitle: (confirm ? "Durdur ve Yeniden Başlat" : "Tamam").localized(language: language))
        if confirm { alert.addButton(withTitle: "Vazgeç".localized(language: language)) }
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    public func killProcesses(_ processIDs: Set<String>) {
        var anyKilled = false
        for id in processIDs {
            if let process = activeProcesses.first(where: { $0.id == id }), process.isKillable {
                if processService.killProcess(pid: process.pid) {
                    anyKilled = true
                }
            }
        }

        if anyKilled {
            DispatchQueue.main.async { [weak self] in
                self?.refreshData()
            }
        }
    }

    // MARK: - Activation Policy

    public func updateActivationPolicy() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.showInDock {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        startTimer()
    }
}
