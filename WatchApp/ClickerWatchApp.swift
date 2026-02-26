import SwiftUI

@main
struct ClickerWatchApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()
    @StateObject private var sessionManager = ExtendedSessionManager()
    @StateObject private var gestureManager = GestureManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(sessionManager)
                .environmentObject(gestureManager)
                .onAppear {
                    wireGestureCallbacks()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        sessionManager.start()
                    case .inactive, .background:
                        gestureManager.stop()
                    @unknown default:
                        break
                    }
                }
        }
    }

    private func wireGestureCallbacks() {
        gestureManager.onNextSlide = { [weak connectionManager] in
            connectionManager?.nextSlide()
        }
        gestureManager.onPreviousSlide = { [weak connectionManager] in
            connectionManager?.previousSlide()
        }
    }
}
