import Foundation
import Combine
import SwiftUI

public enum SortOption: String, CaseIterable, Identifiable {
    case memoryDescending = "RAM (Yüksek > Düşük)"
    case memoryAscending = "RAM (Düşük > Yüksek)"
    case portAscending = "Port (Küçük > Büyük)"
    case processName = "Süreç Adı"

    public var id: String { rawValue }
}

public final class PortMonitorEngine: ObservableObject {
    @Published public var activeProcesses: [PortProcess] = []
    @Published public var searchText: String = ""
    @Published public var sortOption: SortOption = .memoryDescending
    @Published public var filterDevOnly: Bool = true {
        didSet {
            refreshData()
        }
    }
    @Published public var refreshInterval: Double = 5.0 {
        didSet {
            restartTimer()
        }
    }
    @Published public var memoryAlertThresholdMB: Double = 1024.0
    @Published public var notificationsEnabled: Bool = true
    @Published public var lastUpdated: Date = Date()
    @Published public var isRefreshing: Bool = false

    private var timer: Timer?
    private let processManager = ProcessManager.shared
    private let notificationManager = NotificationManager.shared

    public init() {
        notificationManager.requestAuthorization()
        refreshData()
        startTimer()
    }

    deinit {
        stopTimer()
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
            let processes = self.processManager.fetchActivePorts(showOnlyDev: self.filterDevOnly)

            DispatchQueue.main.async {
                self.activeProcesses = processes
                self.lastUpdated = Date()
                if self.notificationsEnabled {
                    self.notificationManager.checkAndNotifyHighMemory(
                        processes: processes,
                        thresholdMB: self.memoryAlertThresholdMB
                    )
                }
            }
        }
    }

    public func killProcess(_ process: PortProcess) {
        let success = processManager.killProcess(pid: process.pid)
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.activeProcesses.removeAll { $0.pid == process.pid }
                self?.refreshData()
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
