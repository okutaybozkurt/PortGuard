import Foundation
import UserNotifications

public final class NotificationManager: NotificationServiceProtocol {
    public static let shared = NotificationManager()
    private var notifiedPIDs: Set<Int> = []

    public init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    public func checkAndNotifyHighMemory(processes: [PortProcess], thresholdMB: Double) {
        for process in processes where process.memoryMB >= thresholdMB {
            if !notifiedPIDs.contains(process.pid) {
                sendHighMemoryNotification(process: process)
                notifiedPIDs.insert(process.pid)
            }
        }

        // Clean up PIDs that are no longer running
        let currentPIDs = Set(processes.map { $0.pid })
        notifiedPIDs = notifiedPIDs.intersection(currentPIDs)
    }

    private func sendHighMemoryNotification(process: PortProcess) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Yüksek RAM Tüketimi Uyarısı"
        content.subtitle = "\(process.processName) (Port: \(process.port))"
        content.body = "\(process.processName) süreci \(process.formattedMemory) RAM tüketiyor! Sonlandırmak için PortGuard'ı kullanabilirsiniz."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "PortGuard-HighMem-\(process.pid)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error delivering notification: \(error)")
            }
        }
    }
}
