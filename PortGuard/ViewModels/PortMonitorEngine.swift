import Foundation
import Combine
import SwiftUI
import AppKit

public enum SortOption: String, CaseIterable, Identifiable {
    case memoryDescending = "RAM (Yüksek > Düşük)"
    case memoryAscending = "RAM (Düşük > Yüksek)"
    case cpuDescending = "CPU (Yüksek > Düşük)"
    case portAscending = "Port (Küçük > Büyük)"
    case processName = "Süreç Adı"

    public var id: String { rawValue }
}

public final class PortMonitorEngine: ObservableObject {
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

    private var timer: Timer?
    private let processService: ProcessServiceProtocol
    private let notificationService: NotificationServiceProtocol

    public init(
        processService: ProcessServiceProtocol = ProcessManager.shared,
        notificationService: NotificationServiceProtocol = NotificationManager.shared
    ) {
        self.processService = processService
        self.notificationService = notificationService

        self.notificationService.requestAuthorization()
        refreshData()
        startTimer()
    }

    deinit {
        stopTimer()
    }

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

        switch sortOption {
        case .memoryDescending:
            result.sort { $0.memoryMB > $1.memoryMB }
        case .memoryAscending:
            result.sort { $0.memoryMB < $1.memoryMB }
        case .cpuDescending:
            result.sort { $0.cpuPercent > $1.cpuPercent }
        case .portAscending:
            result.sort { $0.port < $1.port }
        case .processName:
            result.sort { $0.processName.lowercased() < $1.processName.lowercased() }
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

    public func refreshData() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let keywords = self.customKeywordsList
            let processes = self.processService.fetchActivePorts(showOnlyDev: self.filterDevOnly, customDevKeywords: keywords)

            DispatchQueue.main.async {
                self.activeProcesses = processes
                self.lastUpdated = Date()
                if self.notificationsEnabled {
                    self.notificationService.checkAndNotifyHighMemory(
                        processes: processes,
                        thresholdMB: self.memoryAlertThresholdMB
                    )
                }
            }
        }
    }

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
