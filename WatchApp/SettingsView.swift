import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Clicker Remote v1.8")
                        .font(.system(size: 15))
                }
            } footer: {
                Text("Use the large button, Digital Crown, or double-tap gesture (watchOS 11+) to advance slides. Rotate the crown clockwise for next slide, counterclockwise for previous.")
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
    }
}
