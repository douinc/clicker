import SwiftUI

@main
struct ClickerWatchApp: App {
    @StateObject private var connectionManager = WatchConnectionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
        }
    }
}
