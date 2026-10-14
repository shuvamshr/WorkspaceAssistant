import SwiftUI

/// An inline parameter "token", like the variable pills in a Shortcuts action.
public struct TokenPill: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 3)
            .background(.tint.opacity(0.18), in: Radius.chipShape)
    }
}

#Preview("Light") {
    HStack { TokenPill("Refactor Network Layer"); TokenPill("Focus") }.padding()
}

#Preview("Dark") {
    TokenPill("Focus").padding().preferredColorScheme(.dark)
}

#Preview("AX5") {
    TokenPill("Refactor Network Layer").dynamicTypeSize(.accessibility5)
}

#Preview("RTL") {
    TokenPill("تركيز").environment(\.layoutDirection, .rightToLeft)
}
