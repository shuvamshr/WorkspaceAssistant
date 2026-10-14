import Foundation

/// Localised copy for assistant errors and availability.
enum AssistantCopy {
    static func message(for error: AssistantError) -> String {
        switch error {
        case let .unavailable(reason): unavailableMessage(reason)
        case .contextWindowExceeded:
            String(localized: "This conversation got too long, so I started a fresh one and kept a short summary. Please send that again.")
        case .guardrailViolation:
            String(localized: "I can’t help with that request. Try rephrasing it as something to do with your tasks.")
        case .refusal:
            String(localized: "I can’t help with that. I can organise, add, complete and prioritise your tasks.")
        case .unsupportedLanguage:
            String(localized: "I don’t support this language yet. Try writing in a language Apple Intelligence supports.")
        case .rateLimited:
            String(localized: "I’m getting a lot of requests right now. Wait a moment and try again.")
        case .busy:
            String(localized: "I’m still working on your last request.")
        case .assetsUnavailable:
            String(localized: "The on-device model isn’t ready yet. Try again in a little while.")
        case .timeout:
            String(localized: "That took too long. Please try again.")
        case .other:
            String(localized: "Something went wrong, and nothing was changed. Please try again.")
        }
    }

    static func unavailableMessage(_ reason: AssistantUnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            String(localized: "Apple Intelligence isn’t available on this device.")
        case .appleIntelligenceNotEnabled:
            String(localized: "Apple Intelligence is turned off. Turn it on in Settings to use the full assistant.")
        case .modelNotReady:
            String(localized: "Apple Intelligence is still getting ready. The full assistant will be available once the model finishes downloading.")
        case .unsupportedLanguage:
            String(localized: "Apple Intelligence doesn’t support your current language yet.")
        case .simulatedByConfiguration:
            String(localized: "The simulated assistant is turned on for testing.")
        }
    }

    static var simulatedTitle: String {
        String(localized: "Simulated assistant")
    }

    static var simulatedDetail: String {
        String(localized: "It understands short, simple requests.")
    }
}
