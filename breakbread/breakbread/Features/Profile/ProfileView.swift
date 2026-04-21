import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: BBSpacing.xl) {
                profileHeader
                menuSection
                aboutSection
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: BBSpacing.md) {
            BBAvatar(name: appState.currentUser.displayName, size: 72)

            Text(appState.currentUser.displayName)
                .font(BBFont.title)
                .foregroundStyle(BBColor.primaryText)

            if let email = appState.currentUser.email {
                Text(email)
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BBSpacing.xl)
    }

    // MARK: - Menu

    private var isSubscribed: Bool {
        SubscriptionService.shared.isSubscribed
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            premiumMenuRow(icon: "chart.bar.fill", title: "spending tracker") {
                router.push(.spendingTracker)
            }
            Divider().padding(.leading, 56)
            menuRow(icon: "person.2.fill", title: "saved parties") {
                router.push(.savedParties)
            }
            Divider().padding(.leading, 56)
            premiumMenuRow(icon: "heart.fill", title: "favorites") {
                router.push(.favorites)
            }
            Divider().padding(.leading, 56)
            premiumMenuRow(icon: "bookmark.fill", title: "wishlist") {
                router.push(.wishlist)
            }
            Divider().padding(.leading, 56)
            menuRow(icon: "gearshape.fill", title: "settings") {
                router.push(.settings)
            }
            Divider().padding(.leading, 56)
            menuRow(icon: "star.fill", title: "breakbread+") {
                showPaywall = true
            }
        }
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BBSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(BBColor.secondaryText)
                    .frame(width: 24)

                Text(title)
                    .font(BBFont.body)
                    .foregroundStyle(BBColor.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.md)
            .padding(.vertical, BBSpacing.md)
        }
    }

    private func premiumMenuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            if isSubscribed {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: BBSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSubscribed ? BBColor.secondaryText : BBColor.border)
                    .frame(width: 24)

                Text(title)
                    .font(BBFont.body)
                    .foregroundStyle(isSubscribed ? BBColor.primaryText : BBColor.border)

                if !isSubscribed {
                    Text("plus")
                        .font(BBFont.small)
                        .foregroundStyle(BBColor.onAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BBColor.accent)
                        .clipShape(Capsule())
                }

                Spacer()

                if isSubscribed {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BBColor.secondaryText)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(BBColor.border)
                }
            }
            .padding(.horizontal, BBSpacing.md)
            .padding(.vertical, BBSpacing.md)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: BBSpacing.md) {
            Text("breakbread.")
                .font(BBFont.bodyBold)
                .foregroundStyle(BBColor.secondaryText)
            Text("v1.0")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
        }
        .padding(.top, BBSpacing.lg)
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(Router())
}
