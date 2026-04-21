import SwiftUI
import SwiftData

struct SpendingTrackerView: View {
    @Query(sort: \SavedSplit.createdAt, order: .reverse) private var splits: [SavedSplit]
    @State private var cachedMonthly: [MonthlyData] = []
    @State private var cachedTopSpots: [RestaurantStat] = []
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedAvgSplit: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: BBSpacing.xl) {
                header
                summaryCards
                monthlyChart
                topRestaurants
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
        .task(id: splits.count) {
            recomputeAggregates()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("spending")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)
                Text("this month")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
            Spacer()
        }
        .padding(.top, BBSpacing.md)
    }

    private var summaryCards: some View {
        HStack(spacing: BBSpacing.sm) {
            statCard(title: "total spent", value: CurrencyFormatter.formatShort(cachedTotalSpent))
            statCard(title: "avg split", value: CurrencyFormatter.formatShort(cachedAvgSplit))
            statCard(title: "splits", value: "\(splits.count)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: BBSpacing.sm) {
            Text(value)
                .font(BBFont.sectionHeader)
                .foregroundStyle(BBColor.primaryText)
            Text(title)
                .font(BBFont.small)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BBSpacing.lg)
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("monthly")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            BBCard {
                if cachedMonthly.isEmpty {
                    Text("start splitting to see your spending trends")
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BBSpacing.xl)
                } else {
                    let maxAmount = cachedMonthly.map(\.amount).max() ?? 1

                    VStack(spacing: BBSpacing.sm) {
                        ForEach(cachedMonthly, id: \.label) { data in
                            HStack(spacing: BBSpacing.sm) {
                                Text(data.label)
                                    .font(BBFont.caption)
                                    .foregroundStyle(BBColor.secondaryText)
                                    .frame(width: 36, alignment: .leading)

                                GeometryReader { geo in
                                    let width = (data.amount / maxAmount) * geo.size.width
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(BBColor.accent)
                                        .frame(width: max(width, 4), height: 20)
                                }
                                .frame(height: 20)

                                Text(CurrencyFormatter.formatCompact(data.amount))
                                    .font(BBFont.small)
                                    .foregroundStyle(BBColor.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private var topRestaurants: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("top spots")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            if cachedTopSpots.isEmpty {
                BBCard {
                    Text("your favorite restaurants will show up here")
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BBSpacing.lg)
                }
            } else {
                ForEach(Array(cachedTopSpots.prefix(5).enumerated()), id: \.offset) { index, spot in
                    HStack(spacing: BBSpacing.md) {
                        Text("\(index + 1)")
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.secondaryText)
                            .frame(width: 24)

                        Text(spot.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)

                        Spacer()

                        Text("\(spot.count)x")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.secondaryText)

                        Text(CurrencyFormatter.formatShort(spot.total))
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)
                    }
                    .padding(.vertical, BBSpacing.xs)
                }
            }
        }
    }

    // MARK: - Aggregate Computation (off body)

    private func recomputeAggregates() {
        cachedTotalSpent = splits.reduce(0) { $0 + $1.userShare }
        cachedAvgSplit = splits.isEmpty ? 0 : cachedTotalSpent / Double(splits.count)

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var monthlyGrouped: [Date: Double] = [:]
        for split in splits {
            let comps = calendar.dateComponents([.year, .month], from: split.createdAt)
            if let monthStart = calendar.date(from: comps) {
                monthlyGrouped[monthStart, default: 0] += split.userShare
            }
        }
        cachedMonthly = monthlyGrouped
            .sorted { $0.key < $1.key }
            .map { MonthlyData(label: formatter.string(from: $0.key), amount: $0.value) }

        var restaurantGrouped: [String: (count: Int, total: Double)] = [:]
        for split in splits {
            let name = split.restaurantName ?? "Unknown"
            let existing = restaurantGrouped[name] ?? (0, 0)
            restaurantGrouped[name] = (existing.count + 1, existing.total + split.userShare)
        }
        cachedTopSpots = restaurantGrouped
            .map { RestaurantStat(name: $0.key, count: $0.value.count, total: $0.value.total) }
            .sorted { $0.count > $1.count }
    }

    struct MonthlyData {
        let label: String
        let amount: Double
    }

    struct RestaurantStat: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let total: Double
    }
}

#Preview {
    SpendingTrackerView()
        .modelContainer(for: SavedSplit.self, inMemory: true)
}
