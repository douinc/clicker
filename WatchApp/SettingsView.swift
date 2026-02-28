import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gestureManager: GestureManager

    var body: some View {
        List {
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
