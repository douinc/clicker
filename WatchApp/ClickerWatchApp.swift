import SwiftUI

@main
struct ClickerWatchApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()
    @StateObject private var sessionManager = ExtendedSessionManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(sessionManager)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        sessionManager.start()
                    }
                }
        }
    }
}
