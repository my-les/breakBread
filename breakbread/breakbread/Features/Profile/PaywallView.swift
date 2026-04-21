import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: String = "com.breakbread.plus.yearly"
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    header
                    featuresList
                    planSelection
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.md)
                .padding(.bottom, 120)
            }

            bottomBar
        }
        .background(BBColor.background)
        .task {
            await subscriptionService.loadProducts()
        }
        .alert("error", isPresented: $showError) {
            Button("ok") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: BBSpacing.md) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(width: 32, height: 32)
                }
            }

            Text("breakbread+")
                .font(BBFont.courier(36, weight: .bold))
                .foregroundStyle(BBColor.primaryText)

            Text("unlock the full experience")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
        }
    }

    // MARK: - Features

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            featureRow(icon: "doc.text.viewfinder", title: "unlimited scans", desc: "scan as many receipts as you want")
            featureRow(icon: "chart.bar.fill", title: "spending insights", desc: "weekly & monthly analytics, top restaurants")
            featureRow(icon: "person.2.fill", title: "unlimited parties", desc: "save groups of friends you eat with")
            featureRow(icon: "gamecontroller.fill", title: "games", desc: "guess the bill, random payer, late penalties")
            featureRow(icon: "bookmark.fill", title: "city wishlist", desc: "save spots & get suggestions by city")
            featureRow(icon: "bolt.fill", title: "priority processing", desc: "faster OCR & no ads")
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: BBSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BBColor.primaryText)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)
                Text(desc)
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
        }
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: BBSpacing.sm) {
            planCard(
                id: "com.breakbread.plus.yearly",
                title: "yearly",
                price: subscriptionService.yearlyProduct?.displayPrice ?? "$29.99",
                subtitle: "save 37%",
                badge: "best value"
            )

            planCard(
                id: "com.breakbread.plus.monthly",
                title: "monthly",
                price: subscriptionService.monthlyProduct?.displayPrice ?? "$3.99",
                subtitle: "per month",
                badge: nil
            )
        }
    }

    private func planCard(id: String, title: String, price: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selectedPlan == id

        return Button {
            selectedPlan = id
            HapticManager.selection()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BBSpacing.sm) {
                        Text(title)
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)
                        if let badge {
                            Text(badge)
                                .font(BBFont.small)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(BBColor.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                }

                Spacer()

                Text(price)
                    .font(BBFont.sectionHeader)
                    .foregroundStyle(BBColor.primaryText)
            }
            .padding(BBSpacing.md)
            .background(isSelected ? BBColor.cardSurface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: BBRadius.md)
                    .strokeBorder(isSelected ? BBColor.accent : BBColor.border, lineWidth: isSelected ? 2 : 1)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: BBSpacing.sm) {
            Divider()

            BBButton(title: "subscribe", isLoading: isPurchasing) {
                Task { await subscribe() }
            }
            .padding(.horizontal, BBSpacing.lg)

            Button("restore purchases") {
                Task { await subscriptionService.restorePurchases() }
            }
            .font(BBFont.caption)
            .foregroundStyle(BBColor.secondaryText)

            Text("Cancel anytime. Terms apply.")
                .font(BBFont.small)
                .foregroundStyle(BBColor.secondaryText)
                .padding(.bottom, BBSpacing.sm)
        }
        .background(BBColor.background)
    }

    private func subscribe() async {
        let product: Product?
        if selectedPlan == "com.breakbread.plus.yearly" {
            product = subscriptionService.yearlyProduct
        } else {
            product = subscriptionService.monthlyProduct
        }

        guard let product else {
            errorMessage = "Product not available. Please try again later."
            showError = true
            return
        }

        isPurchasing = true
        do {
            let success = try await subscriptionService.purchase(product)
            if success {
                HapticManager.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

#Preview {
    PaywallView()
}
