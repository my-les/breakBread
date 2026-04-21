import SwiftUI

/// Games launched from the bill split flow; uses party + receipt totals from `SplitFlowViewModel`.
struct SplitGamesHubView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    private enum GamePath: Hashable {
        case guess, late, random
    }

    @State private var path = NavigationPath()

    private var seed: SplitGameSeed {
        SplitGameSeed(
            memberNames: vm.members.map(\.name),
            subtotal: vm.subtotal,
            tax: vm.tax
        )
    }

    private var hasEnoughPlayers: Bool {
        vm.members.count >= 2
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: BBSpacing.lg) {
                flowHeader(title: "party games", step: "your group & receipt") {
                    nav.back()
                }

                if !hasEnoughPlayers {
                    BBCard {
                        HStack(spacing: BBSpacing.sm) {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(BBColor.secondaryText)
                            Text("add at least two people in party setup to play most games.")
                                .font(BBFont.caption)
                                .foregroundStyle(BBColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, BBSpacing.lg)
                }

                VStack(spacing: BBSpacing.md) {
                    gameCard(
                        icon: "questionmark.bubble.fill",
                        title: "guess the bill",
                        description: "everyone guesses the total — closest wins",
                        game: .guess
                    )

                    gameCard(
                        icon: "clock.badge.exclamationmark.fill",
                        title: "late = you pay",
                        description: "set a timer — latecomers add to their share",
                        game: .late
                    )

                    gameCard(
                        icon: "dice.fill",
                        title: "random payer",
                        description: "spin to pick who covers the bill",
                        game: .random
                    )
                }
                .padding(.horizontal, BBSpacing.lg)

                Spacer()
            }
            .background(BBColor.background)
            .navigationBarHidden(true)
            .navigationDestination(for: GamePath.self) { game in
                switch game {
                case .guess:
                    GuessTheBillView(seed: seed)
                case .late:
                    LatePenaltyView(seed: seed)
                case .random:
                    RandomPayerView(seed: seed)
                }
            }
        }
    }

    private func gameCard(icon: String, title: String, description: String, game: GamePath) -> some View {
        Button {
            path.append(game)
            HapticManager.tap()
        } label: {
            HStack(spacing: BBSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(BBColor.primaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)
                    Text(description)
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(BBSpacing.md)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
        }
        .disabled(game == .guess && !hasEnoughPlayers)
        .opacity(game == .guess && !hasEnoughPlayers ? 0.45 : 1)
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.members = [
        PartyMember(name: "You", isCurrentUser: true),
        PartyMember(name: "Alex"),
    ]
    vm.subtotal = 48.50
    vm.tax = 4.12

    return SplitGamesHubView()
        .environment(vm)
        .environment(\.splitFlowNav, SplitFlowNavigation())
}
