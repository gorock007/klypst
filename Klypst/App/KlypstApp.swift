import KlypstCore
import SwiftUI

@main
struct KlypstApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment.state)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    environment.state.bumpChangeToken()
                    environment.refreshClipboardNudge()
                    Task { await environment.runRetention() }
                }
        }
    }
}
