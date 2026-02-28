import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
    @EnvironmentObject var gestureManager: GestureManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var timerStartDate: Date?
    @State private var accumulatedTime: TimeInterval = 0
    @State private var timerRunning = false
    @State private var showSettings = false

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
                VStack(spacing: 6) {
                    // Previous slide button
                    Button(action: {
                        WKInterfaceDevice.current().play(.directionDown)
                        connectionManager.previousSlide()
                    }) {
                        ZStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 32, weight: .bold))

                            if gestureManager.lastGesture == .previous {
                                Image(systemName: "hand.wave.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                    .offset(x: 40, y: -10)
                                    .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.30)
                        .background(
                            gestureManager.lastGesture == .previous
                                ? Color.yellow.opacity(0.3)
                                : Color.blue.opacity(isLuminanceReduced ? 0.1 : 0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(.easeOut(duration: 0.2), value: gestureManager.lastGesture)
                    }
                    .buttonStyle(.plain)

                    // Timer + gesture toggle + settings row
                    HStack(spacing: 4) {
                        // Gesture toggle — tap or hardware double-tap to toggle
                        Button {
                            gestureManager.toggle()
                            WKInterfaceDevice.current().play(gestureManager.isEnabled ? .stop : .start)
                        } label: {
                            Image(systemName: gestureManager.isEnabled ? "hand.wave.fill" : "hand.wave")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(gestureManager.isEnabled ? .yellow : .secondary)
                                .frame(width: 30, height: 30)
                                .background(
                                    gestureManager.isEnabled
                                        ? Color.yellow.opacity(0.15)
                                        : Color.white.opacity(0.08)
                                )
                                .clipShape(Circle())
                                .animation(.easeOut(duration: 0.2), value: gestureManager.isEnabled)
                        }
                        .buttonStyle(.plain)
                        .modifier(PrimaryGestureShortcut())

                        Spacer()

                        // Timer — tap to start/stop, long press to reset
                        VStack(spacing: 2) {
                            Text(formattedTime(at: context.date))
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
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
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            SettingsView()
                                .environmentObject(gestureManager)
                        }
                    }

                    // Next slide button
                    Button(action: {
                        WKInterfaceDevice.current().play(.directionUp)
                        connectionManager.nextSlide()
                    }) {
                        ZStack {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 32, weight: .bold))

                            if gestureManager.lastGesture == .next {
                                Image(systemName: "hand.wave.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                    .offset(x: 40, y: -10)
                                    .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.30)
                        .background(
                            gestureManager.lastGesture == .next
                                ? Color.yellow.opacity(0.3)
                                : Color.blue.opacity(isLuminanceReduced ? 0.1 : 0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(.easeOut(duration: 0.2), value: gestureManager.lastGesture)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
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
        .environmentObject(GestureManager())
}
