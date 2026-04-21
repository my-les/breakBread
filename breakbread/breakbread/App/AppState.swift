import SwiftUI
import AuthenticationServices

@Observable
class AppState {
    var isAuthenticated: Bool
    var currentUser: UserProfile
    var isLoading = false
    var showOnboarding: Bool

    private static let userKey = "breakbread_current_user"
    private static let authKey = "breakbread_is_authenticated"

    var isGuestSession: Bool {
        isAuthenticated && currentUser.id == UserProfile.guest.id
    }

    var canSignOut: Bool {
        isAuthenticated && !isGuestSession
    }

    init() {
        let wasAuthenticated = UserDefaults.standard.bool(forKey: Self.authKey)

        if wasAuthenticated,
           let data = UserDefaults.standard.data(forKey: Self.userKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
            self.showOnboarding = false
        } else {
            self.currentUser = .guest
            self.isAuthenticated = false
            self.showOnboarding = true
        }
    }

    func signIn(user: UserProfile) {
        currentUser = user
        isAuthenticated = true
        showOnboarding = false
        persistSession()
    }

    func signOut() {
        currentUser = .guest
        isAuthenticated = false
        showOnboarding = true
        clearPersistedSession()
    }

    func checkAppleIDCredentialState() {
        guard !isGuestSession, isAuthenticated else { return }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: currentUser.id) { state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    break
                case .revoked, .notFound:
                    self.signOut()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Persistence

    private func persistSession() {
        UserDefaults.standard.set(true, forKey: Self.authKey)
        if let data = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(data, forKey: Self.userKey)
        }
    }

    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: Self.authKey)
        UserDefaults.standard.removeObject(forKey: Self.userKey)
    }
}
