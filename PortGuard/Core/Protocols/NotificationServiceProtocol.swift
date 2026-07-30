import Foundation

public protocol NotificationServiceProtocol {
    func requestAuthorization()
    func checkAndNotifyHighMemory(processes: [PortProcess], thresholdMB: Double)
}
