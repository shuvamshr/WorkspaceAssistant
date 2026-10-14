/// Failures an assistant engine reports, each with specific UI copy.
public enum AssistantError: Error, Hashable, Sendable {
    /// The model can't be used right now.
    case unavailable(AssistantUnavailableReason)
    /// The conversation outgrew the context window. A fresh session was started with a summary.
    case contextWindowExceeded
    /// The request or response tripped the safety guardrails.
    case guardrailViolation
    /// The model declined to help with the request.
    case refusal
    /// The prompt's language isn't supported.
    case unsupportedLanguage
    /// Too many requests; try again shortly.
    case rateLimited
    /// A response is already in progress.
    case busy
    /// The model assets aren't available (e.g. still downloading).
    case assetsUnavailable
    /// The request timed out.
    case timeout
    /// Anything else, with a debug description for logs.
    case other(String)
}
