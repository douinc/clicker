import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var timerStartDate: Date?
    @State private var accumulatedTime: TimeInterval = 0
    @State private var timerRunning = false
    @State private var showSettings = false
    @State private var crownOffset: Double = 0
    @State private var lastCrownDetent: Int = 0
    @AppStorage("invertCrown") private var invertCrown = false

    private func elapsedTime(at date: Date) -> TimeInterval {
        if timerRunning, let start = timerStartDate {
            return accumulatedTime + date.timeIntervalSince(start)
        }
        return accumulatedTime
    }

    private func formattedTime(at date: Date) -> String {
        let total = Int(elapsedTime(at: date))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geometry in
                VStack(spacing: 2) {
                    Button(action: {
                        WKInterfaceDevice.current().play(.directionUp)
                        connectionManager.nextSlide()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                            .background(Color.blue.opacity(isLuminanceReduced ? 0.15 : 0.35))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .modifier(PrimaryGestureShortcut())

                    Spacer()

                    // Bottom row: Previous, Timer, Settings
                    HStack(spacing: 8) {
                        // Previous slide — small circular button
                        Button(action: {
                            WKInterfaceDevice.current().play(.directionDown)
                            connectionManager.previousSlide()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(isLuminanceReduced ? 0.1 : 0.25))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Timer — tap to start/stop, long press to reset
                        VStack(spacing: 2) {
                            Text(formattedTime(at: context.date))
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
                                .foregroundColor(timerRunning ? .green : .white)

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(connectionManager.isConnectedToMac ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(connectionManager.isConnectedToMac ? "Connected" : "Disconnected")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .opacity(isLuminanceReduced ? 0.6 : 1.0)
                        .onTapGesture {
                            toggleTimer()
                        }
                        .onLongPressGesture {
                            resetTimer()
                        }

                        Spacer()

                        // Settings button
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            SettingsView()
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .focusable()
        .digitalCrownRotation(
            $crownOffset,
            from: -10000.0,
            through: 10000.0,
            sensitivity: .medium,
            isContinuous: true
        )
        .onChange(of: crownOffset) { _, newValue in
            let detent = Int(newValue.rounded())
            guard detent != lastCrownDetent else { return }
            let isForward = invertCrown ? (detent < lastCrownDetent) : (detent > lastCrownDetent)
            WKInterfaceDevice.current().play(.click)
            if isForward {
                connectionManager.nextSlide()
            } else {
                connectionManager.previousSlide()
            }
            lastCrownDetent = detent
        }
    }

    // MARK: - Timer

    private func resetTimer() {
        timerStartDate = nil
        accumulatedTime = 0
        timerRunning = false
        WKInterfaceDevice.current().play(.notification)
    }

    private func toggleTimer() {
        if timerRunning {
            accumulatedTime = elapsedTime(at: Date())
            timerStartDate = nil
            timerRunning = false
            WKInterfaceDevice.current().play(.stop)
        } else {
            timerStartDate = Date()
            timerRunning = true
            WKInterfaceDevice.current().play(.start)
        }
    }
}

/// Applies `.handGestureShortcut(.primaryAction)` on watchOS 11+, which maps
/// the hardware double-tap gesture to this button. On watchOS 10 the button
/// remains tap-only; the modifier is a no-op.
private struct PrimaryGestureShortcut: ViewModifier {
    func body(content: Content) -> some View {
        if #available(watchOS 11.0, *) {
            content.handGestureShortcut(.primaryAction)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectionManager())
}
