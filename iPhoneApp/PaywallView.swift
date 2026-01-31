import SwiftUI
import StoreKit

/// URLs for legal documents required by App Store guidelines 3.1.2
private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
private let privacyPolicyURL = URL(string: "https://douinc.github.io/clicker/privacy")!

/// Paywall view using Apple's SubscriptionStoreView for purchase flow
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SubscriptionStoreView(groupID: subscriptionGroupID) {
            VStack(spacing: 16) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("ClickerRemote Pro")
                    .font(.largeTitle.bold())

                Text("Control your presentations with ease")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(text: "Wireless slide control")
                    FeatureRow(text: "Presentation timer with haptics")
                    FeatureRow(text: "One-tap connection")
                }
                .padding(.top)
            }
            .padding()
        }
        .subscriptionStoreControlStyle(.buttons)
        .subscriptionStoreButtonLabel(.action)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(url: termsOfUseURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: privacyPolicyURL, for: .privacyPolicy)
        .onInAppPurchaseCompletion { _, result in
            if case .success = result {
                Task {
                    await subscriptionManager.updateSubscriptionStatus()
                }
                dismiss()
            }
        }
        .task {
            // Check subscription status when paywall appears
            // This handles cases where user already has a subscription
            await subscriptionManager.updateSubscriptionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Refresh subscription status when app becomes active
            // This handles purchases made outside the app (e.g., via Settings > Subscriptions)
            if newPhase == .active {
                Task {
                    await subscriptionManager.updateSubscriptionStatus()
                }
            }
        }
    }
}

/// Feature row with checkmark for paywall benefits list
struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
