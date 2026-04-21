import SwiftUI

struct QuickTipView: View {
    @Environment(\.splitFlowNav) private var nav
    @Environment(\.dismissSplitFlow) private var dismissFlow

    @State private var totalText = ""
    @State private var taxText = ""
    @State private var selectedPreset: TipPreset = .twenty
    @State private var customTipText = ""
    @State private var isCustom = false

    private var subtotal: Double {
        Double(totalText.replacingOccurrences(of: "$", with: "")) ?? 0
    }

    private var tax: Double {
        Double(taxText.replacingOccurrences(of: "$", with: "")) ?? 0
    }

    private var tipPercent: Double {
        isCustom ? (Double(customTipText) ?? 0) : selectedPreset.rawValue
    }

    private var tipAmount: Double {
        subtotal * tipPercent / 100
    }

    private var total: Double {
        subtotal + tax + tipAmount
    }

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "quick tip", step: nil) {
                dismissFlow()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    billInput
                    tipSelector
                    resultCard
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.lg)
                .padding(.bottom, 100)
            }

            VStack(spacing: 0) {
                Divider()
                BBButton(title: "done") {
                    HapticManager.success()
                    dismissFlow()
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.vertical, BBSpacing.md)
            }
            .background(BBColor.background)
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
    }

    // MARK: - Bill Input

    private var billInput: some View {
        VStack(spacing: BBSpacing.md) {
            VStack(alignment: .leading, spacing: BBSpacing.xs) {
                Text("BILL TOTAL")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(0.5)

                HStack(spacing: BBSpacing.xs) {
                    Text("$")
                        .font(BBFont.heroNumber)
                        .foregroundStyle(BBColor.secondaryText)
                    TextField("0.00", text: $totalText)
                        .font(BBFont.courier(40, weight: .bold))
                        .foregroundStyle(BBColor.primaryText)
                        .keyboardType(.decimalPad)
                }
            }

            BBInputField(label: "TAX (OPTIONAL)", text: $taxText, placeholder: "0.00", keyboard: .decimalPad)
        }
    }

    // MARK: - Tip Selector

    private var tipSelector: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("tip")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            HStack(spacing: BBSpacing.sm) {
                ForEach(TipPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        isCustom = false
                        customTipText = ""
                        HapticManager.selection()
                    } label: {
                        let selected = !isCustom && selectedPreset == preset
                        Text(preset.label)
                            .font(BBFont.bodyBold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(selected ? BBColor.onAccent : BBColor.primaryText)
                            .background(selected ? BBColor.accent : BBColor.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                    }
                }
            }

            Button {
                isCustom.toggle()
                if !isCustom { customTipText = "" }
            } label: {
                Text(isCustom ? "use preset" : "custom %")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
                    .underline()
            }

            if isCustom {
                HStack(spacing: BBSpacing.sm) {
                    TextField("custom", text: $customTipText)
                        .font(BBFont.body)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(height: 44)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))

                    Text("%")
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.secondaryText)
                }
            }
        }
    }

    // MARK: - Result

    private var resultCard: some View {
        BBCard {
            VStack(spacing: BBSpacing.md) {
                resultRow("subtotal", subtotal)
                resultRow("tax", tax)
                resultRow("tip (\(Int(tipPercent))%)", tipAmount)

                Divider()

                HStack {
                    Text("total")
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                    Spacer()
                    Text(CurrencyFormatter.formatShort(total))
                        .font(BBFont.heroNumber)
                        .foregroundStyle(BBColor.primaryText)
                }
            }
        }
    }

    private func resultRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()
            Text(CurrencyFormatter.formatShort(value))
                .font(BBFont.bodyBold)
                .foregroundStyle(BBColor.primaryText)
        }
    }
}

#Preview {
    QuickTipView()
}
