/// Row density for the List layout. Replaces the prototype's separate "Compact" layout.
public enum ListDensity: String, CaseIterable, Codable, Sendable, Identifiable {
    case comfortable, compact

    public var id: String { rawValue }
}
