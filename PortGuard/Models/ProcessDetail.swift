import Foundation

/// Bir sürecin detay bilgisi. `command` sır içerebilir: yalnızca UI'da gösterilir, loglanmaz.
public struct ProcessDetail: Equatable {
    public let pid: Int
    public let ppid: Int
    public let parentName: String?
    public let cwd: String?
    /// Görüntüleme için birleştirilmiş komut satırı. ÇALIŞTIRMA için KULLANILMAZ; `arguments` kullanılır.
    public let command: String
    /// Gerçek argv (argv[0] dahil). Shell string'ine asla birleştirilmeden çalıştırılır.
    public let arguments: [String]
    public let startedAt: Date?

    public init(pid: Int, ppid: Int, parentName: String?, cwd: String?, command: String, arguments: [String] = [], startedAt: Date?) {
        self.pid = pid
        self.ppid = ppid
        self.parentName = parentName
        self.cwd = cwd
        self.command = command
        self.arguments = arguments
        self.startedAt = startedAt
    }

    /// Yeniden başlatma için gerekli bilgiler (komut + dizin) mevcut mu?
    public var isRestartable: Bool {
        !(arguments.first ?? "").isEmpty && !(cwd ?? "").isEmpty
    }
}
