import Foundation

extension TaskPriority {
    /// Localised priority name.
    public var displayName: String {
        switch self {
        case .normal: String(localized: "Normal priority")
        case .high: String(localized: "High priority")
        }
    }
}

extension TaskStatus {
    /// Localised status name.
    public var displayName: String {
        switch self {
        case .open: String(localized: "Open")
        case .done: String(localized: "Done")
        }
    }
}

extension ListDensity {
    /// Localised density name.
    public var displayName: String {
        switch self {
        case .comfortable: String(localized: "Comfortable")
        case .compact: String(localized: "Compact")
        }
    }
}
