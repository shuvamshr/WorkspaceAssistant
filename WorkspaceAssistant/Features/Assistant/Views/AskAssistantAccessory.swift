import SwiftUI

/// The "Ask Assistant…" pill shown in the tab bar's bottom accessory.
public struct AskAssistantAccessory: View {
    private let action: () -> Void
    @Environment(AssistantModel.self) private var model

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, isActive: model.phase == .responding)
                // Primary colour: the pill floats over arbitrary content, so secondary grey can fail contrast.
                Text(model.phase == .responding ? String(localized: "Assistant is working…") : String(localized: "Ask Assistant…"))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                if model.simulationReason != nil {
                    Text("Simulated")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Ask Assistant"))
        .accessibilityIdentifier("askAssistantButton")
    }
}
