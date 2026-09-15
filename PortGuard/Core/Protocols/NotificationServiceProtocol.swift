import Foundation

public protocol NotificationServiceProtocol {
    func requestAuthorization()
    func checkAndNotifyHighMemory(processes: [PortProcess], thresholdMB: Double)
    /// Send a generic notification with a custom title and body (used by Rule Engine).
    func notify(title: String, body: String)
}
