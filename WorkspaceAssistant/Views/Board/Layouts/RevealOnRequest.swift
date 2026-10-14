import SwiftUI

/// Scrolls to a task when the board asks to reveal it or the assistant changes it.
struct RevealOnRequest: ViewModifier {
    let proxy: ScrollViewProxy
    @Environment(BoardViewModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onChange(of: model.revealRequest) { _, request in
                if let request { scroll(to: request.taskID) }
            }
            .onChange(of: model.store.lastAssistantChange) { _, change in
                if let first = change?.taskIDs.first { scroll(to: first) }
            }
    }

    private func scroll(to id: UUID) {
        withAnimation(reduceMotion ? nil : .smooth) {
            proxy.scrollTo(id, anchor: .center)
        }
    }
}

extension View {
    /// Scrolls `proxy` to tasks the board or assistant asks to reveal.
    func revealsTasks(with proxy: ScrollViewProxy) -> some View {
        modifier(RevealOnRequest(proxy: proxy))
    }
}
