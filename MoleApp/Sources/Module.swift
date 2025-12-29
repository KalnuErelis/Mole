import Foundation

enum MoleModule: String, CaseIterable, Identifiable {
    case overview
    case clean
    case uninstall
    case analyze
    case status
    case optimize
    case purge
    case update

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .clean: return "Clean"
        case .uninstall: return "Uninstall"
        case .analyze: return "Analyze"
        case .status: return "Status"
        case .optimize: return "Optimize"
        case .purge: return "Purge"
        case .update: return "Update"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "Run the interactive Mole menu"
        case .clean: return "Deep system cleanup"
        case .uninstall: return "Remove apps and leftovers"
        case .analyze: return "Disk usage explorer"
        case .status: return "Live system dashboard"
        case .optimize: return "Refresh caches and services"
        case .purge: return "Clean project artifacts"
        case .update: return "Check and install updates"
        }
    }

    var command: String {
        switch self {
        case .overview: return ""
        case .clean: return "clean"
        case .uninstall: return "uninstall"
        case .analyze: return "analyze"
        case .status: return "status"
        case .optimize: return "optimize"
        case .purge: return "purge"
        case .update: return "update"
        }
    }

    var supportsDryRun: Bool {
        self == .clean
    }

    var supportsWhitelist: Bool {
        self == .clean || self == .optimize
    }

    var supportsPaths: Bool {
        self == .purge
    }

    var supportsDebug: Bool {
        true
    }
}

struct ModuleOptions: Equatable {
    var dryRun: Bool = false
    var whitelist: Bool = false
    var managePaths: Bool = false
    var debug: Bool = false
    var extraArgs: String = ""
}
