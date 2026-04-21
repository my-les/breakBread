import SwiftUI

struct GamesHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router

    var body: some View {
        VStack(spacing: BBSpacing.lg) {
            HStack {
                Text("games")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)
                Spacer()
            }
            .padding(.top, BBSpacing.md)

            gameCard(
                icon: "questionmark.bubble.fill",
                title: "guess the bill",
                description: "everyone guesses the total — closest wins",
                route: .guessTheBill
            )

            gameCard(
                icon: "clock.badge.exclamationmark.fill",
                title: "late = you pay",
                description: "set a timer — latecomers add to their share",
                route: .latePenalty
            )

            gameCard(
                icon: "dice.fill",
                title: "random payer",
                description: "spin the wheel to pick who covers the bill",
                route: .randomPayer
            )

            Spacer()
        }
        .padding(.horizontal, BBSpacing.lg)
        .background(BBColor.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gameCard(icon: String, title: String, description: String, route: Route) -> some View {
        Button {
            router.push(route)
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
    }
}

#Preview {
    NavigationStack {
        GamesHubView()
            .environment(Router())
    }
}
