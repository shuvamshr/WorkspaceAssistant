import Foundation
import FoundationModels

/// Maps Foundation Models errors (iOS 26 `GenerationError` and iOS 27 `LanguageModelError`) to `AssistantError`.
enum AssistantErrorMapping {
    static func map(_ error: any Error) -> AssistantError {
        if let mapped = error as? AssistantError { return mapped }
        if #available(iOS 27.0, *), let mapped = mapModern(error) { return mapped }
        if let generation = error as? LanguageModelSession.GenerationError { return map(generation) }
        return .other(String(describing: error))
    }

    /// iOS 26 error type (deprecated in iOS 27 but still the type thrown on iOS 26).
    static func map(_ error: LanguageModelSession.GenerationError) -> AssistantError {
        switch error {
        case .exceededContextWindowSize: .contextWindowExceeded
        case .assetsUnavailable: .assetsUnavailable
        case .guardrailViolation: .guardrailViolation
        case .unsupportedLanguageOrLocale: .unsupportedLanguage
        case .rateLimited: .rateLimited
        case .concurrentRequests: .busy
        case .refusal: .refusal
        case .unsupportedGuide, .decodingFailure: .other(String(describing: error))
        @unknown default: .other(String(describing: error))
        }
    }

    @available(iOS 27.0, *)
    private static func mapModern(_ error: any Error) -> AssistantError? {
        if let error = error as? LanguageModelError {
            switch error {
            case .contextSizeExceeded: return .contextWindowExceeded
            case .rateLimited: return .rateLimited
            case .guardrailViolation: return .guardrailViolation
            case .refusal: return .refusal
            case .unsupportedLanguageOrLocale: return .unsupportedLanguage
            case .timeout: return .timeout
            case .unsupportedCapability, .unsupportedTranscriptContent, .unsupportedGenerationGuide:
                return .other(String(describing: error))
            @unknown default: return .other(String(describing: error))
            }
        }
        if let error = error as? LanguageModelSession.Error {
            switch error {
            case .concurrentRequests: return .busy
            default: return .other(String(describing: error))
            }
        }
        if let error = error as? SystemLanguageModel.Error {
            switch error {
            case .assetsUnavailable: return .assetsUnavailable
            @unknown default: return .other(String(describing: error))
            }
        }
        return nil
    }

    /// Maps the system model's availability.
    static func map(_ availability: SystemLanguageModel.Availability) -> AssistantAvailability {
        switch availability {
        case .available: .available
        case let .unavailable(reason):
            switch reason {
            case .deviceNotEligible: .unavailable(.deviceNotEligible)
            case .appleIntelligenceNotEnabled: .unavailable(.appleIntelligenceNotEnabled)
            case .modelNotReady: .unavailable(.modelNotReady)
            @unknown default: .unavailable(.modelNotReady)
            }
        }
    }
}
