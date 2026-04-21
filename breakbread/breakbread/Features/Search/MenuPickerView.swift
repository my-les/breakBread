import SwiftUI

struct MenuPickerView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    let sections: [MenuSection]

    @State private var selectedItems: [MenuItem: Int] = [:]
    @State private var expandedSections: Set<UUID> = []

    private var totalSelected: Int {
        selectedItems.values.reduce(0, +)
    }

    private var totalPrice: Double {
        selectedItems.reduce(0) { sum, entry in
            sum + entry.key.price * Double(entry.value)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "what did you order?", step: "select from menu") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.md) {
                    ForEach(sections) { section in
                        menuSectionView(section)
                    }
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.md)
                .padding(.bottom, 120)
            }

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            if expandedSections.isEmpty, let first = sections.first {
                expandedSections.insert(first.id)
            }
        }
    }

    // MARK: - Section

    private func menuSectionView(_ section: MenuSection) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            } label: {
                HStack {
                    Text(section.name.lowercased())
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)

                    Text("(\(section.items.count))")
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)

                    Spacer()

                    Image(systemName: expandedSections.contains(section.id) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BBColor.secondaryText)
                }
                .padding(.vertical, BBSpacing.md)
            }

            if expandedSections.contains(section.id) {
                VStack(spacing: 0) {
                    ForEach(section.items) { item in
                        menuItemRow(item)
                    }
                }
            }
        }
    }

    // MARK: - Item Row

    private func menuItemRow(_ item: MenuItem) -> some View {
        let count = selectedItems[item] ?? 0

        return Button {
            HapticManager.selection()
            if count > 0 {
                selectedItems[item] = nil
            } else {
                selectedItems[item] = 1
            }
        } label: {
            HStack(alignment: .top, spacing: BBSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(count > 0 ? BBColor.accent : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(count > 0 ? BBColor.accent : BBColor.border, lineWidth: 1.5)
                        }

                    if count > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BBColor.onAccent)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.primaryText)
                        .multilineTextAlignment(.leading)

                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(BBFont.small)
                            .foregroundStyle(BBColor.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                if item.price > 0 {
                    Text(CurrencyFormatter.formatShort(item.price))
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)
                }
            }
            .padding(.vertical, BBSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: BBSpacing.sm) {
                if totalSelected > 0 {
                    HStack {
                        Text("\(totalSelected) items")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.secondaryText)
                        Spacer()
                        Text(CurrencyFormatter.formatShort(totalPrice))
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)
                    }
                    .padding(.horizontal, BBSpacing.lg)
                    .padding(.top, BBSpacing.sm)
                }

                HStack(spacing: BBSpacing.sm) {
                    Button("skip — scan receipt") {
                        nav.advance(.scan)
                    }
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
                    .frame(maxWidth: .infinity)

                    BBButton(title: "add to bill", isDisabled: totalSelected == 0) {
                        addSelectedItems()
                        HapticManager.tap()
                        nav.advance(.party)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.bottom, BBSpacing.md)
            }
        }
        .background(BBColor.background)
    }

    // MARK: - Helpers

    private func addSelectedItems() {
        for (item, qty) in selectedItems where qty > 0 {
            vm.addLineItem(name: item.name, price: item.price, quantity: qty)
        }
    }
}

#Preview {
    let sections = [
        MenuSection(name: "Appetizers", items: [
            MenuItem(name: "Spicy Tuna Tartare", description: "With avocado and crispy wontons", price: 18.00),
            MenuItem(name: "Rock Shrimp Tempura", description: nil, price: 24.00),
        ]),
        MenuSection(name: "Entrees", items: [
            MenuItem(name: "Black Cod Miso", description: "Signature dish with miso glaze", price: 36.00),
            MenuItem(name: "Wagyu Beef", description: nil, price: 62.00),
        ]),
    ]

    return MenuPickerView(sections: sections)
        .environment(SplitFlowViewModel())
}
