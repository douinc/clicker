import SwiftUI
import HealthKit

@main
struct ClickerWatchApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()
    @StateObject private var sessionManager = ExtendedSessionManager()
    @StateObject private var gestureManager = GestureManager()
    @StateObject private var workoutManager = WorkoutManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(sessionManager)
                .environmentObject(gestureManager)
                .environmentObject(workoutManager)
                .onAppear {
                    wireGestureCallbacks()
                    workoutManager.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        sessionManager.start()
                        workoutManager.start()
                        if gestureManager.autoToggleWithWrist {
                            gestureManager.start()
                        }
                    case .inactive:
                        if gestureManager.autoToggleWithWrist {
                            gestureManager.stop()
                        }
                    case .background:
                        // User explicitly navigated away — stop workout to save battery
                        workoutManager.stop()
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
