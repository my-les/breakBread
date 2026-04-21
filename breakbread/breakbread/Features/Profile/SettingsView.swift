import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var venmoUsername = ""
    @State private var cashAppUsername = ""
    @State private var defaultTip: TipPreset = .twenty
    @State private var hapticEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: BBSpacing.xl) {
                paymentAccountsSection
                preferencesSection
                accountSection
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.top, BBSpacing.md)
            .padding(.bottom, BBSpacing.xxl)
        }
        .background(BBColor.background)
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Payment Accounts

    private var paymentAccountsSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("payment accounts")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            BBInputField(
                label: "VENMO USERNAME",
                text: $venmoUsername,
                placeholder: "@username"
            )

            BBInputField(
                label: "CASH APP",
                text: $cashAppUsername,
                placeholder: "$cashtag"
            )
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("preferences")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            BBCard {
                VStack(spacing: BBSpacing.md) {
                    HStack {
                        Text("default tip")
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        Spacer()
                        Picker("", selection: $defaultTip) {
                            ForEach(TipPreset.allCases) { preset in
                                Text(preset.label).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(BBFont.body)
                    }

                    Divider()

                    Toggle(isOn: $hapticEnabled) {
                        Text("haptic feedback")
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                    }
                    .tint(BBColor.accent)
                }
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(spacing: BBSpacing.md) {
            if appState.canSignOut {
                BBButton(title: "sign out", style: .secondary) {
                    appState.signOut()
                }
            } else if appState.isGuestSession {
                BBButton(title: "sign in with apple", style: .secondary) {
                    appState.signOut()
                }
            }
        }
        .padding(.top, BBSpacing.lg)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
    }
}
