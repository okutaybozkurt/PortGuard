import Foundation

/// Özellik 5 — Project port info extracted from scanning a project directory.
public struct ProjectPortInfo: Equatable {
    public let projectURL: URL
    public let projectName: String
    public let projectType: ProjectType
    public let expectedPorts: [Int]
    public let sourceFile: String   // e.g. "package.json", ".env"

    public enum ProjectType: String, Equatable {
        case node    = "Node.js"
        case flutter = "Flutter"
        case python  = "Python"
        case docker  = "Docker Compose"
        case generic = "Generic"

        public var iconName: String {
            switch self {
            case .node:    return "square.stack.3d.up.fill"
            case .flutter: return "iphone"
            case .python:  return "chevron.left.forwardslash.chevron.right"
            case .docker:  return "shippingbox.fill"
            case .generic: return "doc.fill"
            }
        }

        public var accentColor: String {
            switch self {
            case .node:    return "green"
            case .flutter: return "blue"
            case .python:  return "yellow"
            case .docker:  return "cyan"
            case .generic: return "gray"
            }
        }
    }

    public init(
        projectURL: URL,
        projectName: String,
        projectType: ProjectType,
        expectedPorts: [Int],
        sourceFile: String
    ) {
        self.projectURL    = projectURL
        self.projectName   = projectName
        self.projectType   = projectType
        self.expectedPorts = expectedPorts
        self.sourceFile    = sourceFile
    }
}
