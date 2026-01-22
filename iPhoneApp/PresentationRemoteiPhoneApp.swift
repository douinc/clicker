import SwiftUI

// MARK: - iPhone App Entry Point
@main
struct ClickerApp: App {
    @StateObject private var connectionManager = iPhoneConnectionManager()
    @StateObject private var presentationTimer = PresentationTimer()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            SubscriptionGateView(connectionManager: connectionManager, timer: presentationTimer)
                .environment(subscriptionManager)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Subscription Gate View
/// Gates the app behind subscription/trial status
struct SubscriptionGateView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @ObservedObject var connectionManager: iPhoneConnectionManager
    @ObservedObject var timer: PresentationTimer
    @State private var showPaywall = false

    var body: some View {
        Group {
            switch subscriptionManager.status {
            case .notDetermined:
                // Loading state
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

            case .trial, .subscribed:
                // Full access
                ContentView(connectionManager: connectionManager, timer: timer)
                    .overlay(alignment: .top) {
                        if let days = subscriptionManager.trialDaysRemaining {
                            TrialBannerView(daysRemaining: days) {
                                showPaywall = true
                            }
                        }
                    }

            case .expired:
                // Paywall
                PaywallView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Trial Banner View
/// Shows remaining trial days with upgrade prompt
struct TrialBannerView: View {
    let daysRemaining: Int
    let onUpgrade: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(.orange)

            Text("Trial: \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left")
                .font(.subheadline.weight(.medium))

            Spacer()

            Button("Upgrade") {
                onUpgrade()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager
    @ObservedObject var timer: PresentationTimer

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if connectionManager.isConnected {
                RemoteControlView(connectionManager: connectionManager, timer: timer)
            } else {
                ConnectionView(connectionManager: connectionManager)
            }
        }
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon / Status
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)

                    Image(systemName: connectionManager.isSearching ? "antenna.radiowaves.left.and.right" : "rectangle.inset.filled.and.cursorarrow")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(connectionManager.isSearching ? .white : .secondary)
                        .symbolEffect(.pulse, isActive: connectionManager.isSearching)
                }

                Text("Clicker")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(connectionManager.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Available Macs
            if !connectionManager.availableMacs.isEmpty {
                VStack(spacing: 12) {
                    ForEach(connectionManager.availableMacs, id: \.displayName) { mac in
                        Button {
                            connectionManager.connectTo(mac)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "desktopcomputer")
                                    .font(.title3)
                                Text(mac.displayName)
                                    .font(.body.weight(.medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Instructions
            VStack(spacing: 4) {
                Text("Ensure the Mac app is running")
                Text("Both devices on the same network")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Remote Control View (Vertical Layout)
struct RemoteControlView: View {
    @ObservedObject var connectionManager: iPhoneConnectionManager
    @ObservedObject var timer: PresentationTimer
    @State private var showDisconnectConfirm = false
    @State private var showTimerSettings = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Status Bar
                StatusBarView(
                    macName: connectionManager.connectedMac?.displayName ?? "Connected",
                    onDisconnect: { showDisconnectConfirm = true }
                )

                // Main Control Area - Vertical Buttons (Golden Ratio: Next is φ times larger than Previous)
                GeometryReader { buttonGeometry in
                    let spacing: CGFloat = 10
                    let totalHeight = buttonGeometry.size.height - spacing
                    let phi: CGFloat = 1.618 // Golden ratio
                    let previousHeight = totalHeight / (1 + phi)  // ~38.2%
                    let nextHeight = totalHeight - previousHeight  // ~61.8%

                    VStack(spacing: spacing) {
                        // Previous Button (Top - Smaller)
                        SlideButton(
                            direction: .previous,
                            action: { connectionManager.previousSlide() }
                        )
                        .frame(height: previousHeight)

                        // Next Button (Bottom - Larger)
                        SlideButton(
                            direction: .next,
                            action: { connectionManager.nextSlide() }
                        )
                        .frame(height: nextHeight)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Timer Section
                TimerView(timer: timer, showSettings: $showTimerSettings)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .alert("Disconnect?", isPresented: $showDisconnectConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                timer.pause()
                connectionManager.disconnect()
            }
        } message: {
            Text("Disconnect from \(connectionManager.connectedMac?.displayName ?? "this Mac")?")
        }
        .sheet(isPresented: $showTimerSettings) {
            TimerSettingsView(timer: timer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Status Bar
struct StatusBarView: View {
    let macName: String
    let onDisconnect: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text(macName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Disconnect", action: onDisconnect)
                .font(.subheadline)
                .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Slide Button
enum SlideDirection {
    case previous, next

    var icon: String {
        switch self {
        case .previous: return "chevron.left"
        case .next: return "chevron.right"
        }
    }

    var label: String {
        switch self {
        case .previous: return "Previous"
        case .next: return "Next"
        }
    }
}

struct SlideButton: View {
    let direction: SlideDirection
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: direction.icon)
                    .font(.system(size: 56, weight: .ultraLight))
                Text(direction.label)
                    .font(.title3.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(GlassButtonStyle())
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Timer View
struct TimerView: View {
    @ObservedObject var timer: PresentationTimer
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            if let progress = timer.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                        Capsule()
                            .fill(progressColor(progress))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
            }

            // Time Display
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.formattedTime)
                        .font(.system(size: 40, weight: .light, design: .monospaced))
                        .foregroundStyle(timerColor)

                    if let remaining = timer.formattedRemainingTime {
                        Text(remaining + " remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Controls
                HStack(spacing: 12) {
                    // Reset
                    Button {
                        timer.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)

                    // Play/Pause
                    Button {
                        timer.toggle()
                    } label: {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(timer.isRunning ? Color.orange : Color.green, in: Circle())
                    }
                    .buttonStyle(.plain)

                    // Settings
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var timerColor: Color {
        if let total = timer.config.totalDuration {
            if timer.elapsedTime >= total {
                return .red
            } else if timer.elapsedTime >= total * 0.9 {
                return .orange
            }
        }
        return .white
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.9 { return .orange }
        if progress >= 0.75 { return .yellow }
        return .green
    }
}

// MARK: - Timer Settings View
struct TimerSettingsView: View {
    @ObservedObject var timer: PresentationTimer
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // Vibration Toggle
                Section {
                    Toggle("Haptic Alerts", isOn: $timer.config.isEnabled)
                } footer: {
                    Text("Receive haptic feedback at intervals during your presentation")
                }

                // Vibration Interval
                Section("Interval") {
                    ForEach(TimerConfig.presets, id: \.interval) { preset in
                        Button {
                            timer.config.vibrationInterval = preset.interval
                        } label: {
                            HStack {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if timer.config.vibrationInterval == preset.interval {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                // Duration
                Section {
                    ForEach(TimerConfig.durationPresets, id: \.name) { preset in
                        Button {
                            timer.config.totalDuration = preset.duration
                        } label: {
                            HStack {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if timer.config.totalDuration == preset.duration {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Duration")
                } footer: {
                    Text("Set total duration for progress tracking and overtime alerts")
                }

                // Test
                Section {
                    Button {
                        timer.testVibration()
                    } label: {
                        Label("Test Haptic", systemImage: "waveform")
                    }
                }
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView(connectionManager: iPhoneConnectionManager(), timer: PresentationTimer())
}
