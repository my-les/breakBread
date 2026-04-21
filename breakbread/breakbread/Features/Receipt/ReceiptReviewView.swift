import SwiftUI

struct ReceiptReviewView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var showingAddItem = false
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    @State private var editingItemID: UUID?
    @State private var editName = ""
    @State private var editPrice = ""
    @State private var editingTax = false
    @State private var taxText = ""

    var body: some View {
        @Bindable var vm = vm

        VStack(spacing: 0) {
            flowHeader(title: "review items", step: "step 4 of 6") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.lg) {
                    if vm.restaurant != nil {
                        restaurantHeader
                    }

                    if vm.lineItems.isEmpty {
                        BBCard {
                            VStack(spacing: BBSpacing.sm) {
                                Image(systemName: "text.viewfinder")
                                    .font(.system(size: 28))
                                    .foregroundStyle(BBColor.secondaryText)
                                Text("no items found — add them below")
                                    .font(BBFont.body)
                                    .foregroundStyle(BBColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BBSpacing.md)
                        }
                    }

                    itemsList
                    addItemSection

                    Divider()
                        .padding(.horizontal, BBSpacing.lg)

                    totalsSection
                }
                .padding(.top, BBSpacing.lg)
                .padding(.bottom, BBSpacing.xl)
            }

            partyGamesRow

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
    }

    // MARK: - Restaurant Header

    private var restaurantHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.restaurant?.name ?? "")
                    .font(BBFont.sectionHeader)
                    .foregroundStyle(BBColor.primaryText)
                Text(vm.restaurant?.address ?? "")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, BBSpacing.lg)
    }

    // MARK: - Items List

    private var itemsList: some View {
        VStack(spacing: 0) {
            ForEach(vm.lineItems) { item in
                itemRow(item)
            }
            .onDelete { offsets in
                vm.removeLineItem(at: offsets)
            }
        }
    }

    private func itemRow(_ item: LineItem) -> some View {
        VStack(spacing: 0) {
            if editingItemID == item.id {
                HStack(spacing: BBSpacing.sm) {
                    TextField("name", text: $editName)
                        .font(BBFont.body)
                        .padding(.horizontal, BBSpacing.sm)
                        .frame(height: 40)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))

                    TextField("$0.00", text: $editPrice)
                        .font(BBFont.body)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, BBSpacing.sm)
                        .frame(width: 90, height: 40)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))

                    Button {
                        saveEdit(for: item)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(BBColor.success)
                    }

                    Button {
                        editingItemID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(BBColor.border)
                    }
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.vertical, BBSpacing.sm)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        if item.quantity > 1 {
                            Text("qty: \(item.quantity)")
                                .font(BBFont.caption)
                                .foregroundStyle(BBColor.secondaryText)
                        }
                    }

                    Spacer()

                    Text(CurrencyFormatter.formatShort(item.price))
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)

                    Button {
                        startEditing(item)
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(BBColor.secondaryText)
                    }

                    Button {
                        if let index = vm.lineItems.firstIndex(where: { $0.id == item.id }) {
                            vm.removeLineItem(at: IndexSet(integer: index))
                            HapticManager.tap()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(BBColor.border)
                    }
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.vertical, BBSpacing.sm)
                .contentShape(Rectangle())
                .onTapGesture {
                    startEditing(item)
                }
            }
        }
    }

    private func startEditing(_ item: LineItem) {
        editName = item.name
        editPrice = String(format: "%.2f", item.price)
        editingItemID = item.id
        HapticManager.selection()
    }

    private func saveEdit(for item: LineItem) {
        guard let index = vm.lineItems.firstIndex(where: { $0.id == item.id }) else { return }
        let newPrice = Double(editPrice.replacingOccurrences(of: "$", with: "")) ?? item.price
        let newName = editName.trimmingCharacters(in: .whitespaces)
        if !newName.isEmpty {
            vm.lineItems[index].name = newName
            vm.lineItems[index].price = newPrice
            vm.recalculateSubtotal()
        }
        editingItemID = nil
        HapticManager.tap()
    }

    // MARK: - Add Item

    private var addItemSection: some View {
        VStack(spacing: BBSpacing.sm) {
            if showingAddItem {
                HStack(spacing: BBSpacing.sm) {
                    TextField("item name", text: $newItemName)
                        .font(BBFont.body)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(height: 44)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))

                    TextField("$0.00", text: $newItemPrice)
                        .font(BBFont.body)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, BBSpacing.md)
                        .frame(width: 100, height: 44)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(BBColor.accent)
                    }
                    .disabled(newItemName.isEmpty || newItemPrice.isEmpty)
                }
                .padding(.horizontal, BBSpacing.lg)
            }

            Button {
                showingAddItem.toggle()
            } label: {
                HStack {
                    Image(systemName: showingAddItem ? "chevron.up" : "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text(showingAddItem ? "done adding" : "add item")
                        .font(BBFont.captionBold)
                        .tracking(0.5)
                }
                .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.lg)
        }
    }

    // MARK: - Totals

    private var totalsSection: some View {
        VStack(spacing: BBSpacing.sm) {
            totalRow("subtotal", value: vm.subtotal)
            taxRow
        }
        .padding(.horizontal, BBSpacing.lg)
    }

    private func totalRow(_ label: String, value: Double) -> some View {
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

    private var taxRow: some View {
        HStack {
            Text("tax")
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()

            if editingTax {
                HStack(spacing: BBSpacing.xs) {
                    Text("$")
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.secondaryText)
                    TextField("0.00", text: $taxText)
                        .font(BBFont.bodyBold)
                        .keyboardType(.decimalPad)
                        .frame(width: 70)
                        .padding(.horizontal, BBSpacing.xs)
                        .padding(.vertical, 4)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.sm))

                    Button {
                        vm.tax = Double(taxText.replacingOccurrences(of: "$", with: "")) ?? 0
                        editingTax = false
                        HapticManager.tap()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(BBColor.success)
                    }
                }
            } else {
                Button {
                    taxText = vm.tax > 0 ? String(format: "%.2f", vm.tax) : ""
                    editingTax = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text(CurrencyFormatter.formatShort(vm.tax))
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(BBColor.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Party games (split flow)

    private var partyGamesRow: some View {
        Button {
            HapticManager.tap()
            nav.advance(.gamesHub)
        } label: {
            HStack(spacing: BBSpacing.md) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(BBColor.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("party games")
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)
                    Text("play before you assign — uses your group & subtotal + tax")
                        .font(BBFont.small)
                        .foregroundStyle(BBColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
            .background(BBColor.cardSurface)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("\(vm.lineItems.count) items")
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                    Text(CurrencyFormatter.formatShort(vm.subtotal))
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                }

                Spacer()

                BBButton(title: "assign items") {
                    HapticManager.tap()
                    nav.advance(.assign)
                }
                .frame(width: 180)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
            .padding(.bottom, BBSpacing.sm)
        }
        .background(BBColor.background)
    }

    // MARK: - Helpers

    private func addItem() {
        let price = Double(newItemPrice.replacingOccurrences(of: "$", with: "")) ?? 0
        guard !newItemName.isEmpty, price > 0 else { return }
        vm.addLineItem(name: newItemName, price: price)
        newItemName = ""
        newItemPrice = ""
        HapticManager.tap()
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.lineItems = [
        LineItem(name: "Margherita Pizza", price: 18.00),
        LineItem(name: "Caesar Salad", price: 14.00),
        LineItem(name: "Sparkling Water", quantity: 2, price: 8.00),
    ]
    vm.subtotal = 40.00
    vm.tax = 3.55

    return ReceiptReviewView()
        .environment(vm)
}
