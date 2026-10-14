import SwiftUI

/// The assistant's floating composer: a glass pill with a growing text field and a send / stop button.
///
/// Return sends; Shift-Return inserts a newline (hardware keyboards). Falls back to a solid
/// fill when Reduce Transparency is on.
public struct ComposerBar: View {
    @Binding private var text: String
    private let isResponding: Bool
    private let focus: FocusState<Bool>.Binding
    private let onSend: () -> Void
    private let onStop: () -> Void
    @State private var allowsNewline = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        text: Binding<String>,
        isResponding: Bool,
        focus: FocusState<Bool>.Binding,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        _text = text
        self.isResponding = isResponding
        self.focus = focus
        self.onSend = onSend
        self.onStop = onStop
    }

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    public var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            TextField(text: $text, axis: .vertical) {
                Text("Ask Assistant…")
            }
            .lineLimit(1...5)
            .focused(focus)
            .submitLabel(.send)
            .padding(.vertical, Spacing.xs)
            .padding(.leading, Spacing.m)
            .onKeyPress(.return, phases: .down) { press in
                if press.modifiers.contains(.shift) {
                    allowsNewline = true
                    text.append("\n")
                } else {
                    send()
                }
                return .handled
            }
            .onChange(of: text) { old, new in
                // Software keyboard Return inserts a newline; treat it as send.
                if allowsNewline {
                    allowsNewline = false
                } else if new.count == old.count + 1, new.hasSuffix("\n") {
                    text.removeLast()
                    send()
                }
            }
            .accessibilityIdentifier("assistantComposer")

            Button(action: isResponding ? onStop : send) {
                Image(systemName: isResponding ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .disabled(!isResponding && !canSend)
            .accessibilityLabel(isResponding ? Text("Stop") : Text("Send"))
            .accessibilityIdentifier("assistantSendButton")
            .padding(.trailing, Spacing.xxs)
        }
        .padding(Spacing.xxs)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(.secondarySystemGroupedBackground))
            }
        }
        .glassEffect(reduceTransparency ? .identity : .regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func send() {
        guard canSend, !isResponding else { return }
        onSend()
    }
}

private struct ComposerPreview: View {
    @State var text = ""
    @FocusState var focused: Bool
    var responding = false
    var body: some View {
        VStack {
            Spacer()
            ComposerBar(text: $text, isResponding: responding, focus: $focused, onSend: { text = "" }, onStop: {})
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("Light") { ComposerPreview() }
#Preview("Dark · Responding") { ComposerPreview(responding: true).preferredColorScheme(.dark) }
#Preview("AX5") { ComposerPreview(text: "Prioritise the network refactor").dynamicTypeSize(.accessibility5) }
#Preview("RTL") { ComposerPreview().environment(\.layoutDirection, .rightToLeft) }
