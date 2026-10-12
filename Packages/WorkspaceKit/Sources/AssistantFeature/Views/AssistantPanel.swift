import DesignSystem
import SwiftUI
import UIKit
import WorkspaceDomain

/// The assistant's content: availability banner, transcript (or suggestions) and the composer.
/// Hosted in a sheet on iPhone and an inspector on iPad.
public struct AssistantPanel: View {
    private let onSelectTask: (UUID) -> Void
    @Environment(AssistantModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var composerFocused: Bool

    public init(onSelectTask: @escaping (UUID) -> Void) {
        self.onSelectTask = onSelectTask
    }

    public var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            if model.items.isEmpty {
                if let reason = model.simulationReason {
                    banner(for: reason)
                        .padding(.horizontal, Spacing.m)
                        .padding(.top, Spacing.xs)
                }
                AssistantEmptyState { model.send(suggestion: $0) }
            } else {
                // Once a conversation exists, the banner scrolls with the transcript.
                TranscriptView(items: model.items, onSelectTask: onSelectTask) {
                    if let reason = model.simulationReason { banner(for: reason) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            ComposerBar(
                text: $model.draft,
                isResponding: model.phase == .responding,
                focus: $composerFocused,
                onSend: model.send,
                onStop: model.cancel
            )
            .padding(.horizontal, Spacing.s)
            .padding(.bottom, Spacing.xs)
        }
        .task { await model.prewarm() }
        .onChange(of: model.focusRequest) { composerFocused = true }
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.refreshAvailability() } }
        .onChange(of: model.lastActivity) { _, activity in
            if let activity { AccessibilityNotification.Announcement(activity.spokenSentence).post() }
        }
    }

    private func banner(for reason: AssistantUnavailableReason) -> some View {
        let opensSettings = reason == .appleIntelligenceNotEnabled
        return AvailabilityBanner(
            title: AssistantCopy.simulatedTitle,
            message: "\(AssistantCopy.unavailableMessage(reason)) \(AssistantCopy.simulatedDetail)",
            actionTitle: opensSettings ? String(localized: "Open Settings", bundle: .module) : nil,
            action: opensSettings ? {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } : nil
        )
        .accessibilityIdentifier("simulatedAssistantBanner")
    }
}
