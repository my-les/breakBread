import SwiftUI
import SwiftData

struct SplitHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedSplit.createdAt, order: .reverse) private var splits: [SavedSplit]
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            BBSearchField(text: $searchText, placeholder: "search history")
                .padding(.horizontal, BBSpacing.lg)
                .padding(.bottom, BBSpacing.md)

            if filteredSplits.isEmpty {
                emptyState
            } else {
                splitsList
            }
        }
        .background(BBColor.background)
    }

    private var header: some View {
        HStack {
            Text("history")
                .font(BBFont.title)
                .foregroundStyle(BBColor.primaryText)
            Spacer()
        }
        .padding(.horizontal, BBSpacing.lg)
        .padding(.top, BBSpacing.md)
        .padding(.bottom, BBSpacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: BBSpacing.lg) {
            Spacer()
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)
            Text("no splits yet")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Text("your split history will appear here")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()
        }
    }

    private var splitsList: some View {
        ScrollView {
            LazyVStack(spacing: BBSpacing.sm) {
                ForEach(filteredSplits) { split in
                    splitRow(split)
                }
            }
            .padding(.horizontal, BBSpacing.lg)
        }
    }

    private func splitRow(_ split: SavedSplit) -> some View {
        HStack(spacing: BBSpacing.md) {
            RoundedRectangle(cornerRadius: BBRadius.sm)
                .fill(BBColor.cardSurface)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "receipt")
                        .font(.system(size: 18))
                        .foregroundStyle(BBColor.secondaryText)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(split.restaurantName ?? "Split")
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)

                HStack(spacing: BBSpacing.xs) {
                    Text("\(split.memberCount) people")
                    Text("·")
                    Text(split.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                }
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.formatShort(split.total))
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)
                Text("you: \(CurrencyFormatter.formatShort(split.userShare))")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
        }
        .padding(BBSpacing.md)
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
    }

    private var filteredSplits: [SavedSplit] {
        if searchText.isEmpty { return splits }
        return splits.filter {
            $0.restaurantName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
}

#Preview {
    SplitHistoryView()
        .modelContainer(for: SavedSplit.self, inMemory: true)
}
