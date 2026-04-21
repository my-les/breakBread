import SwiftUI

struct SplitEvenView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var totalText = ""
    @State private var taxText = ""
    @State private var peopleCount = 2

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "even split", step: nil) {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    amountInputs
                    tipSelection
                    peopleSelector
                    previewCard
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.lg)
                .padding(.bottom, 100)
            }

            VStack(spacing: 0) {
                Divider()
                BBButton(title: "view split", isDisabled: vm.subtotal <= 0) {
                    vm.prepareQuickTipMembers(count: peopleCount)
                    vm.isQuickTipFlow = true
                    HapticManager.tap()
                    nav.advance(.summary)
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.vertical, BBSpacing.md)
            }
            .background(BBColor.background)
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            vm.lineItems = []
            vm.isQuickTipFlow = true
            totalText = vm.subtotal > 0 ? String(format: "%.2f", vm.subtotal) : ""
            taxText = vm.tax > 0 ? String(format: "%.2f", vm.tax) : ""
            peopleCount = max(vm.partyCount, 2)
        }
    }

    private var amountInputs: some View {
        BBCard {
            VStack(spacing: BBSpacing.md) {
                BBInputField(label: "BILL TOTAL", text: $totalText, placeholder: "0.00", keyboard: .decimalPad)
                    .onChange(of: totalText) { _, value in
                        vm.subtotal = Double(value.replacingOccurrences(of: "$", with: "")) ?? 0
                    }

                BBInputField(label: "TAX (OPTIONAL)", text: $taxText, placeholder: "0.00", keyboard: .decimalPad)
                    .onChange(of: taxText) { _, value in
                        vm.tax = Double(value.replacingOccurrences(of: "$", with: "")) ?? 0
                    }
            }
        }
    }

    private var tipSelection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("tip")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            HStack(spacing: BBSpacing.sm) {
                ForEach(TipPreset.allCases) { preset in
                    Button {
                        vm.selectTipPreset(preset)
                        HapticManager.selection()
                    } label: {
                        let selected = !vm.isUsingCustomTip && vm.tipPreset == preset
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
        }
    }

    private var peopleSelector: some View {
        BBCard {
            HStack {
                Text("people")
                    .font(BBFont.body)
                    .foregroundStyle(BBColor.primaryText)

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        peopleCount = max(2, peopleCount - 1)
                        vm.partyCount = peopleCount
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 40, height: 40)
                            .foregroundStyle(peopleCount > 2 ? BBColor.primaryText : BBColor.border)
                    }

                    Divider().frame(height: 24)

                    Text("\(peopleCount)")
                        .font(BBFont.sectionHeader)
                        .frame(width: 48)

                    Divider().frame(height: 24)

                    Button {
                        peopleCount += 1
                        vm.partyCount = peopleCount
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 40, height: 40)
                    }
                }
                .foregroundStyle(BBColor.primaryText)
                .background(BBColor.background)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: BBRadius.sm)
                        .strokeBorder(BBColor.border, lineWidth: 1)
                }
            }
        }
    }

    private var previewCard: some View {
        BBCard {
            VStack(spacing: BBSpacing.sm) {
                row("subtotal", vm.subtotal)
                row("tax", vm.tax)
                row("tip (\(Int(vm.tipPercent))%)", vm.tipAmount)
                Divider()
                row("total", vm.total, emphasized: true)
                row("per person", vm.total / Double(max(peopleCount, 1)), emphasized: true)
            }
        }
    }

    private func row(_ label: String, _ value: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? BBFont.bodyBold : BBFont.body)
                .foregroundStyle(emphasized ? BBColor.primaryText : BBColor.secondaryText)
            Spacer()
            Text(CurrencyFormatter.formatShort(value))
                .font(emphasized ? BBFont.bodyBold : BBFont.body)
                .foregroundStyle(BBColor.primaryText)
        }
    }
}

#Preview {
    SplitEvenView()
        .environment(SplitFlowViewModel())
}
