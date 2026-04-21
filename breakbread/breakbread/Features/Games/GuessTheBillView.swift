import SwiftUI

struct GuessTheBillView: View {
    @Environment(\.dismiss) private var dismiss

    /// When set (e.g. from split flow), pre-fills players and suggested actual total.
    var seed: SplitGameSeed?

    @State private var players: [GuessPlayer] = []
    @State private var didApplySeed = false
    @State private var currentPlayerIndex = 0
    @State private var currentGuess = ""
    @State private var actualBillText = ""
    @State private var phase: GamePhase = .addPlayers
    @State private var newPlayerName = ""

    enum GamePhase {
        case addPlayers
        case guessing
        case enterActual
        case results
    }

    struct GuessPlayer: Identifiable {
        let id = UUID()
        var name: String
        var guess: Double = 0
    }

    var body: some View {
        VStack(spacing: BBSpacing.xl) {
            flowHeader(title: "guess the bill", step: phaseLabel) {
                dismiss()
            }

            Spacer()

            switch phase {
            case .addPlayers: addPlayersView
            case .guessing: guessingView
            case .enterActual: enterActualView
            case .results: resultsView
            }

            Spacer()

            bottomActions
        }
        .padding(.horizontal, BBSpacing.lg)
        .padding(.bottom, BBSpacing.lg)
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear { applySeedIfNeeded() }
    }

    init(seed: SplitGameSeed? = nil) {
        self.seed = seed
    }

    private var phaseLabel: String? {
        switch phase {
        case .addPlayers: return "add everyone"
        case .guessing: return "\(players[currentPlayerIndex].name)'s turn"
        case .enterActual: return "reveal time"
        case .results: return nil
        }
    }

    // MARK: - Add Players

    private var addPlayersView: some View {
        VStack(spacing: BBSpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)

            Text("who's playing?")
                .font(BBFont.sectionHeader)
                .foregroundStyle(BBColor.primaryText)

            ForEach(players) { player in
                HStack {
                    BBAvatar(name: player.name, size: 32)
                    Text(player.name)
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.primaryText)
                    Spacer()
                    Button {
                        players.removeAll { $0.id == player.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BBColor.border)
                    }
                }
            }

            HStack(spacing: BBSpacing.sm) {
                TextField("name", text: $newPlayerName)
                    .font(BBFont.body)
                    .padding(.horizontal, BBSpacing.md)
                    .frame(height: 44)
                    .background(BBColor.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                    .onSubmit { addPlayer() }

                Button("add") { addPlayer() }
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.accent)
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Guessing (pass the phone)

    private var guessingView: some View {
        VStack(spacing: BBSpacing.lg) {
            BBAvatar(name: players[currentPlayerIndex].name, size: 72)

            Text(players[currentPlayerIndex].name)
                .font(BBFont.sectionHeader)
                .foregroundStyle(BBColor.primaryText)

            Text("enter your guess")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)

            HStack(spacing: BBSpacing.xs) {
                Text("$")
                    .font(BBFont.heroNumber)
                    .foregroundStyle(BBColor.secondaryText)
                TextField("0.00", text: $currentGuess)
                    .font(BBFont.courier(48, weight: .bold))
                    .foregroundStyle(BBColor.primaryText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 250)

            Text("player \(currentPlayerIndex + 1) of \(players.count)")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
        }
    }

    // MARK: - Enter Actual

    private var enterActualView: some View {
        VStack(spacing: BBSpacing.lg) {
            Image(systemName: "receipt")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)

            Text("what was the actual bill?")
                .font(BBFont.sectionHeader)
                .foregroundStyle(BBColor.primaryText)

            HStack(spacing: BBSpacing.xs) {
                Text("$")
                    .font(BBFont.heroNumber)
                    .foregroundStyle(BBColor.secondaryText)
                TextField("0.00", text: $actualBillText)
                    .font(BBFont.courier(48, weight: .bold))
                    .foregroundStyle(BBColor.primaryText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 250)
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        let actual = Double(actualBillText) ?? 0
        let sorted = players.sorted { abs($0.guess - actual) < abs($1.guess - actual) }

        return VStack(spacing: BBSpacing.lg) {
            if let winner = sorted.first {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "FFD700"))

                Text("\(winner.name) wins!")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)
            }

            VStack(spacing: BBSpacing.sm) {
                HStack {
                    Text("actual bill")
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.secondaryText)
                    Spacer()
                    Text(CurrencyFormatter.formatShort(actual))
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)
                }
                .padding(.bottom, BBSpacing.sm)

                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, player in
                    let diff = abs(player.guess - actual)
                    HStack(spacing: BBSpacing.md) {
                        Text("\(index + 1)")
                            .font(BBFont.bodyBold)
                            .foregroundStyle(index == 0 ? Color(hex: "FFD700") : BBColor.secondaryText)
                            .frame(width: 24)

                        BBAvatar(name: player.name, size: 28)

                        Text(player.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(CurrencyFormatter.formatShort(player.guess))
                                .font(BBFont.bodyBold)
                                .foregroundStyle(BBColor.primaryText)
                            Text("off by \(CurrencyFormatter.formatShort(diff))")
                                .font(BBFont.small)
                                .foregroundStyle(diff < actual * 0.1 ? BBColor.success : BBColor.error)
                        }
                    }
                }
            }
            .padding(BBSpacing.md)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
        }
    }

    // MARK: - Bottom Actions

    @ViewBuilder
    private var bottomActions: some View {
        switch phase {
        case .addPlayers:
            BBButton(title: "start guessing", isDisabled: players.count < 2) {
                phase = .guessing
                currentPlayerIndex = 0
                currentGuess = ""
                HapticManager.tap()
            }
            Text("add at least 2 players")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)

        case .guessing:
            BBButton(title: currentPlayerIndex < players.count - 1 ? "pass the phone" : "all guesses in!", isDisabled: currentGuess.isEmpty) {
                lockInCurrentGuess()
            }

        case .enterActual:
            BBButton(title: "reveal results", isDisabled: actualBillText.isEmpty) {
                withAnimation(.spring(response: 0.4)) {
                    phase = .results
                }
                HapticManager.success()
            }

        case .results:
            BBButton(title: "play again") { resetAll() }
            BBButton(title: "done", style: .secondary) { dismiss() }
        }
    }

    // MARK: - Helpers

    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        players.append(GuessPlayer(name: name))
        newPlayerName = ""
        HapticManager.tap()
    }

    private func lockInCurrentGuess() {
        players[currentPlayerIndex].guess = Double(currentGuess) ?? 0
        HapticManager.impact(.heavy)

        if currentPlayerIndex < players.count - 1 {
            currentPlayerIndex += 1
            currentGuess = ""
        } else {
            phase = .enterActual
            if let seed {
                actualBillText = String(format: "%.2f", seed.suggestedBillTotal)
            } else {
                actualBillText = ""
            }
        }
    }

    private func applySeedIfNeeded() {
        guard !didApplySeed, let seed else { return }
        let cleaned = seed.memberNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard cleaned.count >= 2 else { return }
        didApplySeed = true
        players = cleaned.map { GuessPlayer(name: $0) }
    }

    private func resetAll() {
        players = []
        currentPlayerIndex = 0
        currentGuess = ""
        actualBillText = ""
        phase = .addPlayers
        newPlayerName = ""
        didApplySeed = false
        applySeedIfNeeded()
    }
}

#Preview {
    GuessTheBillView()
}
