import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gestureManager: GestureManager

    var body: some View {
        List {
            Section {
                Toggle(isOn: $gestureManager.gestureLockEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gesture Lock")
                            .font(.system(size: 15))
                    }
                }
            } footer: {
                Text("After a gesture, lock out further gestures for 3 seconds to prevent accidental triggers")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle(isOn: $gestureManager.isInverted) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invert Gestures")
                            .font(.system(size: 15))
                    }
                }
            } footer: {
                Text(gestureManager.isInverted
                     ? "Counterclockwise → Next\nClockwise → Previous"
                     : "Clockwise → Next\nCounterclockwise → Previous")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle(isOn: $gestureManager.autoToggleWithWrist) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-toggle with Wrist")
                            .font(.system(size: 15))
                    }
                }
            } footer: {
                Text("Gestures enable on wrist raise and disable on wrist lower")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(GestureManager())
    }
}
