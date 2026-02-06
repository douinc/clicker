import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
    @State private var elapsedSeconds: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer?

    var body: some View {
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
                        .background(Color.blue.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Timer display (middle) — tap to start/stop, long press to reset
                VStack(spacing: 2) {
                    Text(formattedTime)
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
                        .background(Color.blue.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Timer
    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
        elapsedSeconds = 0
        WKInterfaceDevice.current().play(.notification)
    }

    private func toggleTimer() {
        if timerRunning {
            // Stop timer
            timer?.invalidate()
            timer = nil
            timerRunning = false
        } else {
            // Start timer
            timerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                elapsedSeconds += 1
            }
        }
        WKInterfaceDevice.current().play(.click)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectionManager())
}
