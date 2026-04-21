import SwiftUI

struct RandomPayerView: View {
    @Environment(\.dismiss) private var dismiss

    var seed: SplitGameSeed?

    @State private var names: [String] = [""]
    @State private var didApplySeed = false
    @State private var isSpinning = false
    @State private var selectedName: String?
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: BBSpacing.xl) {
            flowHeader(title: "who's paying?", step: nil) {
                dismiss()
            }

            Spacer()

            if let winner = selectedName {
                winnerView(winner)
            } else {
                namesInput
            }

            Spacer()

            if selectedName == nil {
                BBButton(
                    title: isSpinning ? "choosing..." : "spin the wheel",
                    isLoading: isSpinning,
                    isDisabled: validNames.count < 2
                ) {
                    spin()
                }

                Text("add at least 2 names to play")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            } else {
                BBButton(title: "spin again") { reset() }
                BBButton(title: "done", style: .secondary) { dismiss() }
            }
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

    private var namesInput: some View {
        VStack(spacing: BBSpacing.md) {
            Image(systemName: "dice.fill")
                .font(.system(size: 48))
                .foregroundStyle(BBColor.secondaryText)
                .rotationEffect(.degrees(rotation))

            Text("add everyone's name")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)

            ForEach(names.indices, id: \.self) { index in
                HStack {
                    TextField("name", text: $names[index])
                        .font(BBFont.body)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(height: 44)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))

                    if names.count > 1 {
                        Button {
                            names.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(BBColor.border)
                        }
                    }
                }
            }

            Button {
                names.append("")
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("add name")
                }
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
            }
        }
    }

    private func winnerView(_ name: String) -> some View {
        VStack(spacing: BBSpacing.lg) {
            BBAvatar(name: name, size: 100)

            Text(name)
                .font(BBFont.courier(36, weight: .bold))
                .foregroundStyle(BBColor.primaryText)

            Text("is paying!")
                .font(BBFont.sectionHeader)
                .foregroundStyle(BBColor.secondaryText)
        }
    }

    private var validNames: [String] {
        names.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func spin() {
        isSpinning = true
        HapticManager.impact(.heavy)

        withAnimation(.easeInOut(duration: 2)) {
            rotation += 1080
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                selectedName = validNames.randomElement()
                isSpinning = false
            }
            HapticManager.success()
        }
    }

    private func reset() {
        selectedName = nil
        rotation = 0
    }

    private func applySeedIfNeeded() {
        guard !didApplySeed, let seed else { return }
        let cleaned = seed.memberNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        didApplySeed = true
        if cleaned.count >= 2 {
            names = cleaned
        } else if cleaned.count == 1 {
            names = [cleaned[0], ""]
        }
    }
}

#Preview {
    RandomPayerView()
}
