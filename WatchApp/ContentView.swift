import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
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
                        Image(systemName: "chevron.left")
                            .font(.system(size: 32, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.height * 0.35)
                            .background(Color.blue.opacity(isLuminanceReduced ? 0.1 : 0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    // Timer display (middle) — tap to start/stop, long press to reset
                    VStack(spacing: 2) {
                        Text(formattedTime(at: context.date))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
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
                        Image(systemName: "chevron.right")
                            .font(.system(size: 32, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.height * 0.35)
                            .background(Color.blue.opacity(isLuminanceReduced ? 0.1 : 0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
}
