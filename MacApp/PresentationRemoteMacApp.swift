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
        VStack(alignment: .leading, spacing: 8) {
            // Status Header
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(connectionManager.statusMessage)
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Divider()

            // Connected Devices
            if !connectionManager.connectedDevices.isEmpty {
                Text("Connected:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(connectionManager.connectedDevices, id: \.displayName) { peer in
                    HStack {
                        Image(systemName: "iphone")
                        Text(peer.displayName)
                    }
                    .padding(.leading, 8)
                }

                Divider()
            }

            // Last Command
            if let lastCommand = connectionManager.lastCommand {
                HStack {
                    Text("Last:")
                        .foregroundColor(.secondary)
                    Text(lastCommand.rawValue)
                        .fontWeight(.medium)
                }
                .font(.caption)

                Divider()
            }

            // Controls
            if connectionManager.isAdvertising {
                Button("Stop Listening") {
                    connectionManager.stopAdvertising()
                }
            } else {
                Button("Start Listening") {
                    checkPermissionsAndStart()
                }
            }

            Divider()

            // Accessibility Status
            HStack {
                Image(systemName: KeystrokeSender.shared.hasAccessibilityPermission ?
                      "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(KeystrokeSender.shared.hasAccessibilityPermission ? .green : .orange)
                Text("Accessibility")
                    .font(.caption)

                if !KeystrokeSender.shared.hasAccessibilityPermission {
                    Button("Grant") {
                        KeystrokeSender.shared.requestAccessibilityPermission()
                    }
                    .font(.caption)
                }
            }

            Divider()

            // Test Controls
            Text("Test:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("← Prev") {
                    KeystrokeSender.shared.previousSlide()
                }
                Button("Next →") {
                    KeystrokeSender.shared.nextSlide()
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 220)
        .onAppear {
            setupCommandHandler()
        }
        .onChange(of: connectionManager.connectedDevices) { devices in
            appState.isConnected = !devices.isEmpty
        }
    }

    private var statusColor: Color {
        if !connectionManager.connectedDevices.isEmpty {
            return .green
        } else if connectionManager.isAdvertising {
            return .orange
        } else {
            return .gray
        }
    }

    private func checkPermissionsAndStart() {
        if !KeystrokeSender.shared.hasAccessibilityPermission {
            KeystrokeSender.shared.requestAccessibilityPermission()
        }
        connectionManager.startAdvertising()
    }

    private func setupCommandHandler() {
        connectionManager.onCommandReceived = { command in
            KeystrokeSender.shared.sendCommand(command)
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
