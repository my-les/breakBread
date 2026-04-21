import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView()
                        .navigationDestination(for: Route.self) { route in
                            routeView(route)
                        }
                }
            }

            Tab("history", systemImage: "clock.fill", value: AppTab.history) {
                NavigationStack(path: $router.historyPath) {
                    SplitHistoryView()
                        .navigationDestination(for: Route.self) { route in
                            routeView(route)
                        }
                }
            }

            Tab("profile", systemImage: "person.fill", value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView()
                        .navigationDestination(for: Route.self) { route in
                            routeView(route)
                        }
                }
            }
        }
        .tint(BBColor.primaryText)
    }

    @ViewBuilder
    private func routeView(_ route: Route) -> some View {
        switch route {
        case .splitHistory:
            SplitHistoryView()
        case .spendingTracker:
            SpendingTrackerView()
        case .gamesHub:
            GamesHubView()
        case .guessTheBill:
            GuessTheBillView()
        case .randomPayer:
            RandomPayerView()
        case .latePenalty:
            LatePenaltyView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .savedParties:
            SavedPartiesView()
        case .favorites:
            FavoritesView()
        case .wishlist:
            WishlistView()
        }
    }
}

// MARK: - Favorites View (breakbread+ feature)

struct FavoritesView: View {
    var body: some View {
        VStack(spacing: BBSpacing.lg) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)
            Text("no favorites yet")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Text("save restaurants you love")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()
        }
        .background(BBColor.background)
        .navigationTitle("favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Wishlist View (breakbread+ feature)

struct WishlistView: View {
    var body: some View {
        VStack(spacing: BBSpacing.lg) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)
            Text("no wishlist items")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Text("bookmark places you want to try")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()
        }
        .background(BBColor.background)
        .navigationTitle("wishlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
        .environment(Router())
        .environment(AppState())
        .modelContainer(for: [SavedSplit.self, SavedParty.self], inMemory: true)
}
