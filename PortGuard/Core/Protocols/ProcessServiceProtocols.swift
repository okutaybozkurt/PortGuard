import Foundation

public protocol ProcessFetchingProtocol {
    func fetchActivePorts(showOnlyDev: Bool, customDevKeywords: [String]) -> [PortProcess]
}

public protocol ProcessKillingProtocol {
    func killProcess(pid: Int) -> Bool
}

public typealias ProcessServiceProtocol = ProcessFetchingProtocol & ProcessKillingProtocol
