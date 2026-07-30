import Foundation

public protocol CommandExecutorProtocol: Sendable {
    func runCommand(executable: String, arguments: [String]) -> String
}
