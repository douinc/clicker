import SwiftUI

struct SettingsView: View {
    @AppStorage("invertCrown") private var invertCrown = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $invertCrown) {
                    Label("Invert Crown", systemImage: "digitalcrown.horizontal.arrow.counterclockwise")
                        .font(.system(size: 15))
                }
            } footer: {
                Text(invertCrown
                     ? "Crown clockwise = previous slide, counterclockwise = next slide."
                     : "Crown clockwise = next slide, counterclockwise = previous slide.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Clicker Remote v1.8")
                        .font(.system(size: 15))
                }
            } footer: {
                Text("Use the large button, Digital Crown, or double-tap gesture (watchOS 11+) to advance slides.")
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
