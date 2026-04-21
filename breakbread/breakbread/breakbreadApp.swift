import SwiftUI
import SwiftData

@main
struct breakbreadApp: App {
    @State private var router = Router()
    @State private var appState = AppState()
    @State private var showSplash = true
    @State private var dataReady = false
    @State private var container: ModelContainer?

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let container, dataReady {
                    Group {
                        if appState.isAuthenticated {
                            MainTabView()
                        } else {
                            OnboardingView()
                        }
                    }
                    .environment(router)
                    .environment(appState)
                    .modelContainer(container)
                }

                if showSplash {
                    SplashScreen()
                        .zIndex(1)
                }
            }
            .onAppear { startApp() }
        }
    }

    private func startApp() {
        // Splash dismiss timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }

        // SwiftData on background
        DispatchQueue.global(qos: .userInitiated).async {
            let c = try? ModelContainer(for: SavedSplit.self, SavedParty.self, CrowdsourcedMenuItem.self)
            DispatchQueue.main.async {
                container = c
                dataReady = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            appState.checkAppleIDCredentialState()
        }
    }
}

struct SplashScreen: View {
    @State private var iconScale: CGFloat = 0.92

    var body: some View {
        ZStack {
            BBColor.background
                .ignoresSafeArea()

            VStack(spacing: BBSpacing.lg) {
                Image("launch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .scaleEffect(iconScale)

                Text("breakbread.")
                    .font(BBFont.courier(28, weight: .bold))
                    .foregroundStyle(BBColor.primaryText)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
            }
        }
    }
}
