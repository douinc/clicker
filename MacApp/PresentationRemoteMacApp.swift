import SwiftUI

// MARK: - Mac App Entry Point
@main
struct ClickerMacApp: App {
    @StateObject private var connectionManager = MacConnectionManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu Bar App
        MenuBarExtra {
            MenuBarView(connectionManager: connectionManager, appState: appState)
        } label: {
            if let nsImage = NSImage(named: "MenuBarIcon") {
                Image(nsImage: nsImage)
                    .renderingMode(.template)
            } else {
                // Fallback to SF Symbol if custom icon not found
                Image(systemName: appState.isConnected ? "cursorarrow.click.2" : "cursorarrow.click")
            }
        }

        // Settings Window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isConnected = false
}

// MARK: - Menu Bar View
struct MenuBarView: View {
    @ObservedObject var connectionManager: MacConnectionManager
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            Text(connectionManager.statusMessage)

            if !connectionManager.connectedDevices.isEmpty {
                ForEach(connectionManager.connectedDevices, id: \.displayName) { peer in
                    Label(peer.displayName, systemImage: "iphone")
                }
            }

            if let lastCommand = connectionManager.lastCommand {
                Text("Last: \(lastCommand.rawValue)")
            }

            Divider()

            if connectionManager.isAdvertising {
                Button("Stop Listening") {
                    connectionManager.stopAdvertising()
                }
            } else {
                Button("Start Listening") {
                    if !KeystrokeSender.shared.hasAccessibilityPermission {
                        KeystrokeSender.shared.requestAccessibilityPermission()
                    }
                    connectionManager.startAdvertising()
                }
            }

            Divider()

            if KeystrokeSender.shared.hasAccessibilityPermission {
                Label("Accessibility OK", systemImage: "checkmark.circle")
            } else {
                Button("Grant Accessibility") {
                    KeystrokeSender.shared.requestAccessibilityPermission()
                }
            }

            Divider()

            Button("Test Previous") {
                KeystrokeSender.shared.previousSlide()
            }.keyboardShortcut("[")

            Button("Test Next") {
                KeystrokeSender.shared.nextSlide()
            }.keyboardShortcut("]")

            Divider()

            Button("Restart") {
                let url = Bundle.main.bundleURL
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.createsNewApplicationInstance = true
                NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }.keyboardShortcut("r")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        .onAppear {
            connectionManager.onCommandReceived = { command in
                KeystrokeSender.shared.sendCommand(command)
            }
        }
        .onChange(of: connectionManager.connectedDevices) { devices in
            appState.isConnected = !devices.isEmpty
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        Form {
            Section("About") {
                Text("Clicker")
                    .font(.headline)
                Text("Control presentations from your iPhone")
                    .foregroundColor(.secondary)
            }

            Section("Permissions") {
                HStack {
                    Text("Accessibility Permission")
                    Spacer()
                    if KeystrokeSender.shared.hasAccessibilityPermission {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Grant Permission") {
                            KeystrokeSender.shared.requestAccessibilityPermission()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 320, height: 180)
    }
}
