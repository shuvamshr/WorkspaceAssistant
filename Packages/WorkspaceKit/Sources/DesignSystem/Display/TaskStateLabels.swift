import Foundation
import WorkspaceDomain

extension TaskPriority {
    /// Localised priority name.
    public var displayName: String {
        switch self {
        case .normal: String(localized: "Normal priority", bundle: .module)
        case .high: String(localized: "High priority", bundle: .module)
        }
    }
}

extension TaskStatus {
    /// Localised status name.
    public var displayName: String {
        switch self {
        case .open: String(localized: "Open", bundle: .module)
        case .done: String(localized: "Done", bundle: .module)
        }
    }
}

extension ListDensity {
    /// Localised density name.
    public var displayName: String {
        switch self {
        case .comfortable: String(localized: "Comfortable", bundle: .module)
        case .compact: String(localized: "Compact", bundle: .module)
        }
    }
}
