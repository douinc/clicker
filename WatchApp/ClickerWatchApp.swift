import SwiftUI
import HealthKit

@main
struct ClickerWatchApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()
    @StateObject private var sessionManager = ExtendedSessionManager()
    @StateObject private var workoutManager = WorkoutManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(sessionManager)
                .environmentObject(workoutManager)
                .onAppear {
                    workoutManager.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        sessionManager.start()
                        workoutManager.start()
                    case .inactive:
                        break
                    case .background:
                        workoutManager.stop()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
