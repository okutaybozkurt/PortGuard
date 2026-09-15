import Foundation

/// Represents an active ESTABLISHED TCP connection (outbound/inbound) on the system.
/// Unlike `PortProcess` which only covers LISTEN sockets, `NetworkConnection` captures
/// connections such as browser tabs connecting to remote servers, background syncs, etc.
public struct NetworkConnection: Identifiable, Hashable, Equatable {
    public let id: String
    public let pid: Int
    public let processName: String
    public let user: String
    public let localAddress: String
    public let localPort: Int
    public let remoteAddress: String
    public let remotePort: Int
    public let state: ConnectionState

    public enum ConnectionState: String, Hashable {
        case established = "ESTABLISHED"
        case closeWait   = "CLOSE_WAIT"
        case timeWait    = "TIME_WAIT"
        case synSent     = "SYN_SENT"
        case unknown     = "UNKNOWN"

        public init(rawString: String) {
            switch rawString.uppercased() {
            case "ESTABLISHED": self = .established
            case "CLOSE_WAIT":  self = .closeWait
            case "TIME_WAIT":   self = .timeWait
            case "SYN_SENT":    self = .synSent
            default:            self = .unknown
            }
        }

        public var displayName: String { rawValue }

        public var color: String {
            switch self {
            case .established: return "green"
            case .closeWait:   return "orange"
            case .timeWait:    return "yellow"
            case .synSent:     return "blue"
            case .unknown:     return "gray"
            }
        }
    }

    public init(
        pid: Int,
        processName: String,
        user: String,
        localAddress: String,
        localPort: Int,
        remoteAddress: String,
        remotePort: Int,
        state: ConnectionState = .established
    ) {
        self.id            = "\(pid)-\(localPort)-\(remoteAddress)-\(remotePort)"
        self.pid           = pid
        self.processName   = processName
        self.user          = user
        self.localAddress  = localAddress
        self.localPort     = localPort
        self.remoteAddress = remoteAddress
        self.remotePort    = remotePort
        self.state         = state
    }

    /// Human-readable remote endpoint string, e.g. "api.github.com:443"
    public var remoteEndpoint: String {
        "\(remoteAddress):\(remotePort)"
    }

    /// Human-readable local endpoint string
    public var localEndpoint: String {
        "\(localAddress):\(localPort)"
    }

    /// Well-known port descriptions
    public var remotePortDescription: String? {
        switch remotePort {
        case 80:   return "HTTP"
        case 443:  return "HTTPS"
        case 22:   return "SSH"
        case 25:   return "SMTP"
        case 587:  return "SMTP/TLS"
        case 3306: return "MySQL"
        case 5432: return "PostgreSQL"
        case 6379: return "Redis"
        case 27017: return "MongoDB"
        default:   return nil
        }
    }
}
