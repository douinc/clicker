import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Clicker Remote v1.6")
                        .font(.system(size: 15))
                }
            } footer: {
                Text("Use the large button to advance slides. Double-tap gesture (watchOS 11+) also triggers next slide.")
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
