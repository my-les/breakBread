import SwiftUI
import SwiftData

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SplitFlowViewModel.self) private var vm

    @State private var isFavorite = false
    @State private var isWishlisted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BBSpacing.xl) {
                headerImage
                restaurantInfo
                actionButtons
                detailsSection
            }
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerImage: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(BBColor.cardSurface)
                .frame(height: 200)
                .overlay {
                    Text(String(restaurant.name.prefix(1)))
                        .font(BBFont.courier(72, weight: .bold))
                        .foregroundStyle(BBColor.border)
                }

            LinearGradient(
                colors: [.clear, .black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Info

    private var restaurantInfo: some View {
        VStack(alignment: .leading, spacing: BBSpacing.sm) {
            Text(restaurant.name)
                .font(BBFont.title)
                .foregroundStyle(BBColor.primaryText)

            HStack(spacing: BBSpacing.sm) {
                Label(restaurant.category, systemImage: "fork.knife")
                Text("·")
                Text(restaurant.priceLevelString)
                if restaurant.rating > 0 {
                    Text("·")
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                }
            }
            .font(BBFont.caption)
            .foregroundStyle(BBColor.secondaryText)

            Text(restaurant.address)
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
        }
        .padding(.horizontal, BBSpacing.lg)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: BBSpacing.sm) {
            Button {
                isFavorite.toggle()
                HapticManager.tap()
            } label: {
                Label(
                    isFavorite ? "saved" : "save",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
                .font(BBFont.captionBold)
                .foregroundStyle(isFavorite ? BBColor.error : BBColor.primaryText)
                .padding(.horizontal, BBSpacing.md)
                .padding(.vertical, BBSpacing.sm)
                .background(BBColor.cardSurface)
                .clipShape(Capsule())
            }

            Button {
                isWishlisted.toggle()
                HapticManager.tap()
            } label: {
                Label(
                    isWishlisted ? "wishlisted" : "wishlist",
                    systemImage: isWishlisted ? "bookmark.fill" : "bookmark"
                )
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.primaryText)
                .padding(.horizontal, BBSpacing.md)
                .padding(.vertical, BBSpacing.sm)
                .background(BBColor.cardSurface)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, BBSpacing.lg)
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("details")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            BBCard {
                VStack(alignment: .leading, spacing: BBSpacing.md) {
                    detailRow(icon: "mappin", text: restaurant.address)
                    detailRow(icon: "tag.fill", text: restaurant.category)
                    detailRow(icon: "dollarsign.circle", text: restaurant.priceLevelString)
                    if restaurant.rating > 0 {
                        detailRow(icon: "star.fill", text: "\(String(format: "%.1f", restaurant.rating)) rating")
                    }
                }
            }
        }
        .padding(.horizontal, BBSpacing.lg)
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: BBSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(BBColor.secondaryText)
                .frame(width: 20)
            Text(text)
                .font(BBFont.body)
                .foregroundStyle(BBColor.primaryText)
        }
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(
            restaurant: Restaurant(
                id: "1",
                name: "Carbone",
                address: "181 Thompson St, New York, NY",
                category: "Italian",
                priceLevel: 4,
                rating: 4.7
            )
        )
        .environment(SplitFlowViewModel())
    }
}
