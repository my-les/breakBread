import SwiftUI

enum Route: Hashable {
    case splitHistory
    case spendingTracker
    case gamesHub
    case guessTheBill
    case randomPayer
    case latePenalty
    case profile
    case settings
    case savedParties
    case favorites
    case wishlist
}

enum AppTab: Hashable {
    case home
    case history
    case profile
}

@Observable
class Router {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var historyPath = NavigationPath()
    var profilePath = NavigationPath()

    func push(_ route: Route) {
        switch selectedTab {
        case .home:
            homePath.append(route)
        case .history:
            historyPath.append(route)
        case .profile:
            profilePath.append(route)
        }
    }

    func pop() {
        switch selectedTab {
        case .home where !homePath.isEmpty:
            homePath.removeLast()
        case .history where !historyPath.isEmpty:
            historyPath.removeLast()
        case .profile where !profilePath.isEmpty:
            profilePath.removeLast()
        default:
            break
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .home:
            homePath = NavigationPath()
        case .history:
            historyPath = NavigationPath()
        case .profile:
            profilePath = NavigationPath()
        }
    }
}
