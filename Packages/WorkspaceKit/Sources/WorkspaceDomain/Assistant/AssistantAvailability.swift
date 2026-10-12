/// Whether an assistant engine can respond.
public enum AssistantAvailability: Hashable, Sendable {
    case available
    case unavailable(AssistantUnavailableReason)

    /// Convenience for `== .available`.
    public var isAvailable: Bool { self == .available }
}

/// Why Apple Intelligence (or an engine) can't be used.
public enum AssistantUnavailableReason: Hashable, Sendable {
    /// The device doesn't support Apple Intelligence.
    case deviceNotEligible
    /// Apple Intelligence is turned off in Settings.
    case appleIntelligenceNotEnabled
    /// The model is still downloading or preparing.
    case modelNotReady
    /// The current language isn't supported by the model.
    case unsupportedLanguage
    /// The simulated assistant was chosen explicitly (UI tests, previews).
    case simulatedByConfiguration
}
