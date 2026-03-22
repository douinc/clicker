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
                .onAppear {
                    sessionManager.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        sessionManager.start()
                    case .inactive, .background:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}
