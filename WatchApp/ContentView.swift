import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
    @EnvironmentObject var gestureManager: GestureManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var timerStartDate: Date?
    @State private var accumulatedTime: TimeInterval = 0
    @State private var timerRunning = false

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
                VStack(spacing: 8) {
                    // Previous slide button (top)
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        connectionManager.previousSlide()
                    }) {
                        ZStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 32, weight: .bold))

                            // Gesture feedback overlay
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

                    // Timer display (middle) — tap to start/stop, long press to reset
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

                    // Next slide button (bottom)
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        connectionManager.nextSlide()
                    }) {
                        ZStack {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 32, weight: .bold))

                            // Gesture feedback overlay
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

                    // Gesture control toggle
                    Button(action: {
                        gestureManager.toggle()
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: gestureManager.isEnabled ? "hand.wave.fill" : "hand.wave")
                                .font(.system(size: 12))
                            Text(gestureManager.isEnabled ? "Gestures On" : "Gestures Off")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(gestureManager.isEnabled ? .yellow : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            gestureManager.isEnabled
                                ? Color.yellow.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        } else {
            timerStartDate = Date()
            timerRunning = true
        }
        WKInterfaceDevice.current().play(.click)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectionManager())
        .environmentObject(GestureManager())
}
