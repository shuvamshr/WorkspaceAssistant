import SwiftUI

/// A banner explaining that the simulated assistant is in use, with an optional action.
public struct AvailabilityBanner: View {
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: "theatermasks.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.footnote.weight(.semibold))
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.s)
        .background(Color(.secondarySystemGroupedBackground), in: Radius.blockShape)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    AvailabilityBanner(title: "Simulated assistant", message: "Apple Intelligence isn’t available on this device, so a simple rule-based assistant is standing in.", actionTitle: "Learn More") {}.padding()
}

#Preview("Dark") {
    AvailabilityBanner(title: "Simulated assistant", message: "Turn on Apple Intelligence in Settings to use the real assistant.", actionTitle: "Open Settings") {}
        .padding().preferredColorScheme(.dark)
}

#Preview("AX5") {
    AvailabilityBanner(title: "Simulated assistant", message: "Apple Intelligence isn’t available on this device.").padding().dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    AvailabilityBanner(title: "Simulated assistant", message: "Apple Intelligence isn’t available on this device.").padding().environment(\.layoutDirection, .rightToLeft)
}
