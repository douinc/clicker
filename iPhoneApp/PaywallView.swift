import SwiftUI
import StoreKit

/// Paywall view using Apple's SubscriptionStoreView for purchase flow
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

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
        .onInAppPurchaseCompletion { _, result in
            if case .success = result {
                dismiss()
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
