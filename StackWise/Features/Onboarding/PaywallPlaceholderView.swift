import SwiftUI

struct PaywallPlaceholderView: View {
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // MARK: Zone 1 — Hero / value prop
                // Phase 7: replace with hero image, headline, and subheadline copy
                Text("Your personalized supplement plan")
                    .font(.swTitle2)
                    .multilineTextAlignment(.center)

                // MARK: Zone 2 — Social proof
                // Phase 7: replace with review stars, quote, and attribution
                Text("[Social proof zone]")
                    .font(.swBody)
                    .foregroundStyle(.textSecondary)

                // MARK: Zone 3 — Pricing
                // Phase 7: replace with StoreKit ProductView / RevenueCat offering
                Text("14-day free trial, then $4.99/month")
                    .font(.swBody)

                // MARK: Zone 4 — CTA
                // Phase 7: replace Button action with RevenueCat purchase flow
                VStack(spacing: 12) {
                    Button("Start Free Trial") { onComplete() }
                        .buttonStyle(.borderedProminent)
                        .tint(.aquaPrimary)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 50)

                    Button("Restore Purchases") { /* Phase 7 — StoreKit restore */ }
                        .font(.swBody)
                        .foregroundStyle(.aquaPrimary)

                    Text("No commitment. Cancel anytime.")
                        .font(.swFootnote)
                        .foregroundStyle(.textSecondary)
                }

            }
            .padding(24)
        }
        .background(Color.backgroundPage.ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }
}
