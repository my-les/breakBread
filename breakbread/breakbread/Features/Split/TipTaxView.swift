import SwiftUI

struct TipTaxView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var customTipText = ""
    @State private var showCustomTip = false
    @State private var taxText = ""

    var body: some View {
        @Bindable var vm = vm

        VStack(spacing: 0) {
            flowHeader(title: "tip & tax", step: "step 6 of 6") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    tipSection
                    taxSection
                    totalPreview
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.xl)
                .padding(.bottom, 100)
            }

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            taxText = vm.tax > 0 ? String(format: "%.2f", vm.tax) : ""
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("tip")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            HStack(spacing: BBSpacing.sm) {
                ForEach(TipPreset.allCases) { preset in
                    tipButton(preset)
                }
            }

            if showCustomTip {
                HStack(spacing: BBSpacing.sm) {
                    TextField("custom %", text: $customTipText)
                        .font(BBFont.body)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(height: 48)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                        .onChange(of: customTipText) { _, val in
                            vm.customTipPercent = Double(val)
                        }

                    Text("%")
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.secondaryText)
                }
            }

            Button {
                showCustomTip.toggle()
                if !showCustomTip {
                    vm.customTipPercent = nil
                    customTipText = ""
                }
            } label: {
                Text(showCustomTip ? "use preset" : "custom amount")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
                    .underline()
            }

            BBCard {
                HStack {
                    Text("tip amount")
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.secondaryText)
                    Spacer()
                    Text(CurrencyFormatter.formatShort(vm.tipAmount))
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                }
            }
        }
    }

    private func tipButton(_ preset: TipPreset) -> some View {
        let isSelected = !vm.isUsingCustomTip && vm.tipPreset == preset

        return Button {
            vm.selectTipPreset(preset)
            showCustomTip = false
            customTipText = ""
            HapticManager.selection()
        } label: {
            Text(preset.label)
                .font(BBFont.bodyBold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(isSelected ? BBColor.onAccent : BBColor.primaryText)
                .background(isSelected ? BBColor.accent : BBColor.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }

    // MARK: - Tax Section

    private var taxSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("tax")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            HStack(spacing: BBSpacing.sm) {
                Text("$")
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.secondaryText)

                TextField("0.00", text: $taxText)
                    .font(BBFont.body)
                    .keyboardType(.decimalPad)
                    .onChange(of: taxText) { _, val in
                        vm.tax = Double(val) ?? 0
                    }
            }
            .padding(.horizontal, BBSpacing.md)
            .frame(height: 48)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }

    // MARK: - Total Preview

    private var totalPreview: some View {
        BBCard {
            VStack(spacing: BBSpacing.md) {
                summaryRow("subtotal", value: vm.subtotal)
                summaryRow("tax", value: vm.tax)
                summaryRow("tip (\(Int(vm.tipPercent))%)", value: vm.tipAmount)

                Divider()

                HStack {
                    Text("total")
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                    Spacer()
                    Text(CurrencyFormatter.formatShort(vm.total))
                        .font(BBFont.heroNumber)
                        .foregroundStyle(BBColor.primaryText)
                }
            }
        }
    }

    private func summaryRow(_ label: String, value: Double) -> some View {
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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            BBButton(title: "view split") {
                HapticManager.tap()
                nav.advance(.summary)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
        .background(BBColor.background)
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.subtotal = 52.00
    vm.tax = 4.62
    return TipTaxView().environment(vm)
}
