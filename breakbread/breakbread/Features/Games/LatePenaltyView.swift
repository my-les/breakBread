import SwiftUI

struct LatePenaltyView: View {
    @Environment(\.dismiss) private var dismiss

    var seed: SplitGameSeed?

    @State private var players: [LatePlayer] = []
    @State private var didApplySeed = false
    @State private var newPlayerName = ""
    @State private var penaltyText = ""
    @State private var timerRunning = false
    @State private var deadline: Date = .now
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var phase: Phase = .setup

    enum Phase {
        case setup
        case waiting
        case results
    }

    struct LatePlayer: Identifiable {
        let id = UUID()
        var name: String
        var arrivedOnTime = false
    }

    var body: some View {
        VStack(spacing: BBSpacing.xl) {
            flowHeader(title: "late = you pay", step: phaseLabel) {
                dismiss()
            }

            Spacer()

            switch phase {
            case .setup: setupView
            case .waiting: waitingView
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
        .onDisappear { timer?.invalidate() }
    }

    init(seed: SplitGameSeed? = nil) {
        self.seed = seed
    }

    private var phaseLabel: String? {
        switch phase {
        case .setup: return "set the rules"
        case .waiting: return "clock is ticking"
        case .results: return nil
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: BBSpacing.lg) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BBColor.secondaryText)

            Text("who's coming to dinner?")
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
            }

            Divider()

            VStack(alignment: .leading, spacing: BBSpacing.sm) {
                Text("penalty amount")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(1)

                HStack {
                    Text("$")
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.secondaryText)
                    TextField("10.00", text: $penaltyText)
                        .font(BBFont.body)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, BBSpacing.md)
                .frame(height: 48)
                .background(BBColor.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))

                Text("late arrivals add this to their share")
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.secondaryText)
            }

            VStack(alignment: .leading, spacing: BBSpacing.sm) {
                Text("timer (minutes)")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(1)

                HStack(spacing: 0) {
                    ForEach([5, 10, 15, 30], id: \.self) { mins in
                        Button {
                            timeRemaining = Double(mins * 60)
                            HapticManager.selection()
                        } label: {
                            Text("\(mins)")
                                .font(BBFont.bodyBold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundStyle(timeRemaining == Double(mins * 60) ? BBColor.onAccent : BBColor.primaryText)
                                .background(timeRemaining == Double(mins * 60) ? BBColor.accent : BBColor.cardSurface)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
            }
        }
    }

    // MARK: - Waiting

    private var waitingView: some View {
        VStack(spacing: BBSpacing.lg) {
            Text(formattedTime)
                .font(BBFont.courier(64, weight: .bold))
                .foregroundStyle(timeRemaining < 60 ? BBColor.error : BBColor.primaryText)
                .contentTransition(.numericText())
                .animation(.snappy, value: timeRemaining)

            Text("tap a name when they arrive")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)

            ForEach($players) { $player in
                Button {
                    player.arrivedOnTime = true
                    HapticManager.success()
                } label: {
                    HStack(spacing: BBSpacing.md) {
                        BBAvatar(name: player.name, size: 36)
                        Text(player.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        Spacer()
                        if player.arrivedOnTime {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BBColor.success)
                                .font(.system(size: 22))
                        } else {
                            Text("here?")
                                .font(BBFont.captionBold)
                                .foregroundStyle(BBColor.onAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(BBColor.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(BBSpacing.sm)
                }
                .disabled(player.arrivedOnTime)
            }
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        let penalty = Double(penaltyText) ?? 10
        let latePlayers = players.filter { !$0.arrivedOnTime }
        let onTimePlayers = players.filter { $0.arrivedOnTime }

        return VStack(spacing: BBSpacing.lg) {
            if latePlayers.isEmpty {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(BBColor.success)
                Text("everyone made it!")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)
            } else {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(BBColor.error)
                Text("time's up!")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)
            }

            BBCard {
                VStack(spacing: BBSpacing.sm) {
                    if !latePlayers.isEmpty {
                        Text("late — +\(CurrencyFormatter.formatShort(penalty)) each")
                            .font(BBFont.captionBold)
                            .foregroundStyle(BBColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(latePlayers) { player in
                            HStack {
                                BBAvatar(name: player.name, size: 28)
                                Text(player.name)
                                    .font(BBFont.body)
                                    .foregroundStyle(BBColor.primaryText)
                                Spacer()
                                Text("+\(CurrencyFormatter.formatShort(penalty))")
                                    .font(BBFont.bodyBold)
                                    .foregroundStyle(BBColor.error)
                            }
                        }
                    }

                    if !onTimePlayers.isEmpty {
                        if !latePlayers.isEmpty { Divider() }

                        Text("on time")
                            .font(BBFont.captionBold)
                            .foregroundStyle(BBColor.success)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(onTimePlayers) { player in
                            HStack {
                                BBAvatar(name: player.name, size: 28)
                                Text(player.name)
                                    .font(BBFont.body)
                                    .foregroundStyle(BBColor.primaryText)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BBColor.success)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom

    @ViewBuilder
    private var bottomActions: some View {
        switch phase {
        case .setup:
            BBButton(title: "start timer", isDisabled: players.count < 2 || timeRemaining <= 0) {
                startTimer()
            }
        case .waiting:
            BBButton(title: "time's up!", style: .destructive) {
                endTimer()
            }
        case .results:
            BBButton(title: "play again") { resetAll() }
            BBButton(title: "done", style: .secondary) { dismiss() }
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let mins = Int(timeRemaining) / 60
        let secs = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        players.append(LatePlayer(name: name))
        newPlayerName = ""
        HapticManager.tap()
    }

    private func startTimer() {
        phase = .waiting
        deadline = Date().addingTimeInterval(timeRemaining)
        HapticManager.impact(.heavy)

        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 {
                endTimer()
            } else {
                timeRemaining = remaining
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func endTimer() {
        timer?.invalidate()
        timer = nil
        withAnimation(.spring(response: 0.4)) {
            phase = .results
        }
        HapticManager.notification(.warning)
    }

    private func resetAll() {
        timer?.invalidate()
        timer = nil
        players = []
        newPlayerName = ""
        penaltyText = ""
        timeRemaining = 0
        phase = .setup
        didApplySeed = false
        applySeedIfNeeded()
    }

    private func applySeedIfNeeded() {
        guard !didApplySeed, let seed else { return }
        let cleaned = seed.memberNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard cleaned.count >= 2 else { return }
        didApplySeed = true
        players = cleaned.map { LatePlayer(name: $0) }
        if penaltyText.isEmpty, seed.suggestedBillTotal > 0 {
            let suggested = min(50, max(5, seed.suggestedBillTotal * 0.08))
            penaltyText = String(format: "%.2f", suggested)
        }
    }
}

#Preview {
    LatePenaltyView()
}
