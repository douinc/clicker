import SwiftUI

// MARK: - iPhone App Entry Point
@main
struct PresentationRemoteiPhoneApp: App {
    @StateObject private var connectionManager = iPhoneConnectionManager()
    @StateObject private var presentationTimer = PresentationTimer()
    
    var body: some Scene {
        WindowGroup {
            ContentView(connectionManager: connectionManager, timer: presentationTimer)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager
    @ObservedObject var timer: PresentationTimer
    
    var body: some View {
        NavigationView {
            Group {
                if connectionManager.isConnected {
                    ClickerView(connectionManager: connectionManager, timer: timer)
                } else {
                    ConnectionView(connectionManager: connectionManager)
                }
            }
            .navigationTitle("Presentation Remote")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Status Icon
            Image(systemName: connectionManager.isSearching ? "wifi" : "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(connectionManager.isSearching ? .blue : .gray)
                .symbolEffect(.pulse, isActive: connectionManager.isSearching)
            
            // Status Message
            Text(connectionManager.statusMessage)
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Search Button
            if !connectionManager.isSearching {
                Button(action: {
                    connectionManager.startBrowsing()
                }) {
                    Label("Search for Mac", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            
            // Available Macs List
            if !connectionManager.availableMacs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Macs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(connectionManager.availableMacs, id: \.displayName) { mac in
                        Button(action: {
                            connectionManager.connectTo(mac)
                        }) {
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .font(.title2)
                                Text(mac.displayName)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text("Make sure the Mac app is running")
                    .font(.caption)
                Text("Both devices must be on the same network")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
        }
        .padding(.top, 40)
    }
}

// MARK: - Clicker View (Main Remote Control)
struct ClickerView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager
    @ObservedObject var timer: PresentationTimer
    @State private var showDisconnectConfirm = false
    @State private var showTimerSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Connected Status Bar
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(connectionManager.connectedMac?.displayName ?? "Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Disconnect") {
                        showDisconnectConfirm = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Main Clicker Buttons
                HStack(spacing: 0) {
                    // Previous Button (Left Half)
                    Button(action: {
                        connectionManager.previousSlide()
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 80, weight: .light))
                            Text("Previous")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue.opacity(0.8))
                    }
                    .buttonStyle(ClickerButtonStyle())
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1)
                    
                    // Next Button (Right Half)
                    Button(action: {
                        connectionManager.nextSlide()
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 80, weight: .light))
                            Text("Next")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                    }
                    .buttonStyle(ClickerButtonStyle())
                }
                .frame(height: geometry.size.height * 0.55)
                
                // Timer Section
                TimerControlView(timer: timer, showSettings: $showTimerSettings)
                    .frame(height: geometry.size.height * 0.35)
            }
        }
        .alert("Disconnect?", isPresented: $showDisconnectConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                timer.pause()
                connectionManager.disconnect()
            }
        } message: {
            Text("Are you sure you want to disconnect from \(connectionManager.connectedMac?.displayName ?? "this Mac")?")
        }
        .sheet(isPresented: $showTimerSettings) {
            TimerSettingsView(timer: timer)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Timer Control View
struct TimerControlView: View {
    @ObservedObject var timer: PresentationTimer
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar (if duration is set)
            if let progress = timer.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                        Rectangle()
                            .fill(progressColor(progress))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
                .cornerRadius(2)
                .padding(.horizontal)
            }
            
            // Timer Display
            HStack(alignment: .center, spacing: 20) {
                // Elapsed Time
                VStack(spacing: 4) {
                    Text(timer.formattedTime)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(timerColor)
                    
                    if let remaining = timer.formattedRemainingTime {
                        Text(remaining)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Interval indicator
                if timer.config.isEnabled {
                    VStack(spacing: 2) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.caption)
                        Text("every")
                            .font(.system(size: 10))
                        Text(formatInterval(timer.config.vibrationInterval))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.top, 8)
            
            // Timer Controls
            HStack(spacing: 20) {
                // Reset Button
                Button(action: {
                    timer.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                // Play/Pause Button
                Button(action: {
                    timer.toggle()
                }) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(timer.isRunning ? Color.orange : Color.green)
                        .clipShape(Circle())
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    private var timerColor: Color {
        if let total = timer.config.totalDuration {
            if timer.elapsedTime >= total {
                return .red
            } else if timer.elapsedTime >= total * 0.9 {
                return .orange
            }
        }
        return .primary
    }
    
    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.9 {
            return .orange
        } else if progress >= 0.75 {
            return .yellow
        }
        return .green
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        if interval >= 60 {
            let minutes = Int(interval) / 60
            return "\(minutes) min"
        } else {
            return "\(Int(interval)) sec"
        }
    }
}

// MARK: - Timer Settings View
struct TimerSettingsView: View {
    @ObservedObject var timer: PresentationTimer
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Vibration Toggle
                Section {
                    Toggle("Vibration Alerts", isOn: $timer.config.isEnabled)
                } footer: {
                    Text("Get haptic feedback at regular intervals during your presentation")
                }
                
                // Vibration Interval
                Section("Vibration Interval") {
                    ForEach(TimerConfig.presets, id: \.interval) { preset in
                        Button(action: {
                            timer.config.vibrationInterval = preset.interval
                        }) {
                            HStack {
                                Text(preset.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if timer.config.vibrationInterval == preset.interval {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Total Duration (optional)
                Section {
                    ForEach(TimerConfig.durationPresets, id: \.name) { preset in
                        Button(action: {
                            timer.config.totalDuration = preset.duration
                        }) {
                            HStack {
                                Text(preset.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if timer.config.totalDuration == preset.duration {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Presentation Duration")
                } footer: {
                    Text("Set a total duration to get special alerts at halfway and when time is up")
                }
                
                // Vibration Patterns Info
                Section("Vibration Patterns") {
                    VibrationPatternRow(
                        icon: "hand.tap",
                        title: "Interval",
                        description: "Single pulse"
                    )
                    VibrationPatternRow(
                        icon: "50.circle",
                        title: "Halfway",
                        description: "Triple pulse"
                    )
                    VibrationPatternRow(
                        icon: "flag.checkered",
                        title: "Time's Up",
                        description: "Long vibration"
                    )
                    VibrationPatternRow(
                        icon: "exclamationmark.triangle",
                        title: "Overtime",
                        description: "Double pulse every 30s"
                    )
                }
                
                // Test Button
                Section {
                    Button(action: {
                        timer.testVibration()
                    }) {
                        HStack {
                            Image(systemName: "waveform")
                            Text("Test Vibration")
                        }
                    }
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Vibration Pattern Row
struct VibrationPatternRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Custom Button Style
struct ClickerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ContentView(connectionManager: iPhoneConnectionManager(), timer: PresentationTimer())
}
