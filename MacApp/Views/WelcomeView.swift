import SwiftUI

/// First-launch onboarding wizard
/// Guides users through Accessibility permission setup
struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Content based on current step
            Group {
                switch viewModel.currentStep {
                case .introduction:
                    IntroductionStepView()
                case .accessibilityPermission:
                    PermissionStepView(viewModel: viewModel)
                case .complete:
                    CompleteStepView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Navigation buttons
            HStack {
                if viewModel.currentStep != .introduction {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if viewModel.currentStep == .complete {
                    Button("Get Started") {
                        // Window closing is handled by onComplete callback in AppDelegate
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Continue") {
                        viewModel.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canProceed)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 560)
        .onDisappear {
            viewModel.stopPermissionPolling()
        }
    }
}

// MARK: - Introduction Step

private struct IntroductionStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Welcome to Clicker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Control your presentations from your iPhone")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "iphone",
                    title: "iPhone Remote",
                    description: "Use your iPhone as a wireless presentation remote"
                )

                FeatureRow(
                    icon: "arrow.left.arrow.right",
                    title: "Simple Controls",
                    description: "Navigate slides with large, easy-to-tap buttons"
                )

                FeatureRow(
                    icon: "wifi",
                    title: "Local Connection",
                    description: "Works over WiFi or personal hotspot"
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Permission Step

private struct PermissionStepView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Status icon
            ZStack {
                Circle()
                    .fill(viewModel.hasPermission ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: viewModel.hasPermission ? "checkmark.shield.fill" : "shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(viewModel.hasPermission ? .green : .orange)
            }

            VStack(spacing: 12) {
                Text(viewModel.hasPermission ? "Permission Granted" : "Permission Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(viewModel.hasPermission
                     ? "Clicker can now control your presentations"
                     : "Clicker needs Accessibility permission to send keystrokes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.hasPermission {
                VStack(spacing: 16) {
                    Text("This allows Clicker to send keyboard shortcuts (like arrow keys) to your presentation software when you tap buttons on your iPhone.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        viewModel.requestPermission()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Open System Settings")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("After granting permission, return here to continue")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .padding(24)
        .onAppear {
            viewModel.startPermissionPolling()
        }
    }
}

// MARK: - Complete Step

private struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Clicker is ready to use")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, text: "Look for the Clicker icon in your menu bar")
                StepRow(number: 2, text: "Open the ClickerRemote app on your iPhone")
                StepRow(number: 3, text: "Tap your Mac's name to connect")
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Make sure both devices are on the same WiFi network")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(24)
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(viewModel: WelcomeViewModel())
}
