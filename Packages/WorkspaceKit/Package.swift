// swift-tools-version: 6.2
import PackageDescription

/// Settings shared by every target: Swift 6 strict concurrency with nonisolated-nonsending async functions.
let coreSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

/// UI modules default to main-actor isolation; domain and agent modules stay explicit.
let uiSettings: [SwiftSetting] = coreSettings + [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "WorkspaceKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "WorkspaceDomain", targets: ["WorkspaceDomain"]),
        .library(name: "WorkspacePersistence", targets: ["WorkspacePersistence"]),
        .library(name: "WorkspaceAgent", targets: ["WorkspaceAgent"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "BoardFeature", targets: ["BoardFeature"]),
        .library(name: "AssistantFeature", targets: ["AssistantFeature"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    ],
    targets: [
        .target(name: "WorkspaceDomain", swiftSettings: coreSettings),
        .target(name: "WorkspacePersistence", dependencies: ["WorkspaceDomain"], swiftSettings: coreSettings),
        .target(name: "WorkspaceAgent", dependencies: ["WorkspaceDomain"], swiftSettings: coreSettings),
        .target(
            name: "DesignSystem",
            dependencies: ["WorkspaceDomain"],
            resources: [.process("Resources")],
            swiftSettings: uiSettings
        ),
        .target(
            name: "BoardFeature",
            dependencies: ["WorkspaceDomain", "DesignSystem"],
            resources: [.process("Resources")],
            swiftSettings: uiSettings
        ),
        .target(
            name: "AssistantFeature",
            dependencies: ["WorkspaceDomain", "DesignSystem"],
            resources: [.process("Resources")],
            swiftSettings: uiSettings
        ),
        .target(
            name: "SettingsFeature",
            dependencies: ["WorkspaceDomain", "DesignSystem"],
            resources: [.process("Resources")],
            swiftSettings: uiSettings
        ),
        .testTarget(name: "WorkspaceDomainTests", dependencies: ["WorkspaceDomain"], swiftSettings: coreSettings),
        .testTarget(
            name: "WorkspacePersistenceTests",
            dependencies: ["WorkspacePersistence", "WorkspaceDomain"],
            swiftSettings: coreSettings
        ),
        .testTarget(
            name: "WorkspaceAgentTests",
            dependencies: ["WorkspaceAgent", "WorkspaceDomain"],
            swiftSettings: coreSettings
        ),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "WorkspaceDomain"], swiftSettings: uiSettings),
        .testTarget(name: "BoardFeatureTests", dependencies: ["BoardFeature", "WorkspaceDomain"], swiftSettings: uiSettings),
        .testTarget(
            name: "AssistantFeatureTests",
            dependencies: ["AssistantFeature", "DesignSystem", "WorkspaceDomain"],
            swiftSettings: uiSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
