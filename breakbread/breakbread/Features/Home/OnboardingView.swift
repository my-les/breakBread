import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var signInError: String?

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("doc.text.viewfinder", "scan your receipt", "snap a photo and we'll itemize it instantly"),
        ("person.2.fill", "split with friends", "assign items to each person — fair and square"),
        ("paperplane.fill", "send requests", "collect from friends via venmo, cash app, or imessage"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("breakbread.")
                .font(BBFont.courier(36, weight: .bold))
                .foregroundStyle(BBColor.primaryText)
                .padding(.bottom, BBSpacing.xxl)

            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 250)

            Spacer()

            VStack(spacing: BBSpacing.md) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    handleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))

                Button("continue as guest") {
                    appState.signIn(user: .guest)
                }
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)

                if let signInError {
                    Text(signInError)
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.error)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
    }

    private func onboardingPage(_ page: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: BBSpacing.lg) {
            Image(systemName: page.icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.primaryText)

            VStack(spacing: BBSpacing.sm) {
                Text(page.title)
                    .font(BBFont.sectionHeader)
                    .foregroundStyle(BBColor.primaryText)

                Text(page.subtitle)
                    .font(BBFont.body)
                    .foregroundStyle(BBColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BBSpacing.xl)
            }
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        signInError = nil

        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let givenName = credential.fullName?.givenName
                let familyName = credential.fullName?.familyName
                let name = [givenName, familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let user = UserProfile(
                    id: credential.user,
                    displayName: name.isEmpty ? "User" : name,
                    email: credential.email,
                    createdAt: .now
                )
                appState.signIn(user: user)
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            signInError = "sign in failed — please try again"
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
