import SwiftUI
import StoreKit

/// URLs for legal documents required by App Store guidelines 3.1.2
private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
private let privacyPolicyURL = URL(string: "https://douinc.github.io/clicker/PRIVACY_POLICY.html")!

/// Custom paywall view with price-first hierarchy to comply with App Store guideline 3.1.2.
/// The billed amount is the most prominent pricing element; trial info is subordinate.
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("ClickerRemote Pro")
                        .font(.largeTitle.bold())

                    Text("Control your presentations with ease")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(text: "Wireless slide control")
                    FeatureRow(text: "Presentation timer with haptics")
                    FeatureRow(text: "One-tap connection")
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 24)

                // Pricing section — billed amount is largest and most prominent
                if let product = subscriptionManager.yearlyProduct {
                    PricingSection(product: product)
                } else if subscriptionManager.productLoadFailed {
                    VStack(spacing: 12) {
                        Text("Unable to load pricing")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task {
                                await subscriptionManager.loadProducts()
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                    }
                    .padding()
                } else {
                    ProgressView("Loading...")
                        .padding()
                }

                // Subscribe button
                if let product = subscriptionManager.yearlyProduct {
                    Button {
                        Task { await purchase(product) }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Subscribe")
                                    .font(.title3.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 4)
                }

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Restore purchases
                Button {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                // Legal links
                HStack(spacing: 16) {
                    Link("Terms of Use", destination: termsOfUseURL)
                    Text("·").foregroundStyle(.secondary)
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(uiColor: .systemBackground))
        .task {
            await subscriptionManager.loadProducts()
            await subscriptionManager.updateSubscriptionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await subscriptionManager.updateSubscriptionStatus()
                }
            }
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}

/// Pricing section with billed amount as the most prominent element.
/// Trial/introductory info is subordinate in size, color, and position.
struct PricingSection: View {
    let product: Product

    var body: some View {
        VStack(spacing: 8) {
            // Primary: billed amount — largest and most prominent
            Text(product.displayPrice + "/year")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Subordinate: trial info — smaller font, secondary color, below price
            if let subscription = product.subscription,
               let introOffer = subscription.introductoryOffer {
                Text(introOfferText(introOffer))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func introOfferText(_ offer: Product.SubscriptionOffer) -> String {
        switch offer.paymentMode {
        case .freeTrial:
            let days = offer.period.value * (offer.period.unit == .day ? 1 : offer.period.unit == .week ? 7 : 30)
            return "\(days)-day free trial included"
        case .payUpFront:
            return "Introductory price: \(offer.displayPrice)"
        case .payAsYouGo:
            return "Introductory price: \(offer.displayPrice)/period"
        default:
            return ""
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
