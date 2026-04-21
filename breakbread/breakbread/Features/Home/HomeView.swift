import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(Router.self) private var router
    @State private var splitVM = SplitFlowViewModel()
    @State private var showingSplitFlow = false
    @Query(sort: \SavedSplit.createdAt, order: .reverse, animation: .default)
    private var savedSplits: [SavedSplit]
    @Query(sort: \SavedParty.lastUsed, order: .reverse)
    private var savedParties: [SavedParty]

    var body: some View {
        ScrollView {
            VStack(spacing: BBSpacing.xl) {
                header
                recentSplitsSection
                quickStartSection
                savedPartiesSection
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
        .fullScreenCover(isPresented: $showingSplitFlow) {
            SplitFlowView()
                .environment(splitVM)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("breakbread.")
                .font(BBFont.title)
                .foregroundStyle(BBColor.primaryText)

            Spacer()

            ShareLink(item: "Split bills with friends — fast. Check out breakbread. https://apps.apple.com/app/breakbread") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(BBColor.primaryText)
            }
        }
        .padding(.top, BBSpacing.md)
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        VStack(spacing: BBSpacing.md) {
            BBButton(title: "split a bill") {
                HapticManager.tap()
                splitVM.reset()
                showingSplitFlow = true
            }

            HStack(spacing: BBSpacing.sm) {
                quickAction(icon: "divide", label: "even split") {
                    splitVM.reset()
                    splitVM.currentStep = .splitEven
                    splitVM.isQuickTipFlow = true
                    showingSplitFlow = true
                }

                quickAction(icon: "percent", label: "quick tip") {
                    splitVM.reset()
                    splitVM.currentStep = .quickTip
                    showingSplitFlow = true
                }

                quickAction(icon: "gamecontroller.fill", label: "games") {
                    router.push(.gamesHub)
                }
            }
        }
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: BBSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(BBFont.caption)
                    .tracking(0.5)
            }
            .foregroundStyle(BBColor.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
        }
    }

    // MARK: - Recent Splits

    private var recentSplitsSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("recent")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            if recentSplits.isEmpty {
                BBCard {
                    VStack(spacing: BBSpacing.sm) {
                        Image(systemName: "receipt")
                            .font(.system(size: 28))
                            .foregroundStyle(BBColor.secondaryText)
                        Text("no splits yet")
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BBSpacing.lg)
                }
            } else {
                ForEach(recentSplits) { split in
                    recentSplitRow(
                        name: split.restaurantName ?? "Split",
                        amount: split.total,
                        date: split.createdAt.formatted(.dateTime.month(.abbreviated).day())
                    )
                }
            }
        }
    }

    private func recentSplitRow(name: String, amount: Double, date: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)
                Text(date)
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
            Spacer()
            Text(CurrencyFormatter.formatShort(amount))
                .font(BBFont.bodyBold)
                .foregroundStyle(BBColor.primaryText)
        }
        .padding(BBSpacing.md)
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
    }

    private var recentSplits: [SavedSplit] { Array(savedSplits.prefix(3)) }

    // MARK: - Saved Parties

    private var savedPartiesSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            HStack {
                Text("your parties")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(1)
                Spacer()
                Button("see all") {
                    router.push(.savedParties)
                }
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BBSpacing.sm) {
                    addPartyCard

                    ForEach(savedParties.prefix(5)) { party in
                        partyChip(party)
                    }
                }
            }
        }
    }

    private var addPartyCard: some View {
        Button {
            router.push(.savedParties)
        } label: {
            VStack(spacing: BBSpacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(BBColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BBColor.secondaryText)
                }
                Text("new party")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
        }
    }

    private func partyChip(_ party: SavedParty) -> some View {
        let members = party.getMembers()

        return Button {
            splitVM.reset()
            splitVM.members = members
            splitVM.partyCount = max(2, members.count)
            splitVM.currentStep = .scan
            showingSplitFlow = true
        } label: {
            VStack(spacing: BBSpacing.xs) {
                HStack(spacing: -6) {
                    ForEach(members.prefix(3)) { member in
                        BBAvatar(name: member.name, size: 28)
                            .overlay(Circle().strokeBorder(BBColor.cardSurface, lineWidth: 2))
                    }
                }
                Text(party.name)
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, BBSpacing.sm)
            .padding(.vertical, BBSpacing.sm)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }
}

#Preview {
    HomeView()
        .environment(Router())
        .modelContainer(for: SavedSplit.self, inMemory: true)
}
