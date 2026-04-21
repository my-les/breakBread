import SwiftUI

struct ItemAssignmentView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var selectedMember: PartyMember?

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "who got what?", step: "step 5 of 6") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            memberSelector
                .padding(.top, BBSpacing.md)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(vm.lineItems) { item in
                        itemRow(item)
                    }
                }
                .padding(.top, BBSpacing.sm)
                .padding(.bottom, BBSpacing.xl)
            }

            partyGamesRow

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            if selectedMember == nil {
                selectedMember = vm.members.first
            }
        }
    }

    // MARK: - Member Selector

    private var memberSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BBSpacing.md) {
                ForEach(vm.members) { member in
                    VStack(spacing: 4) {
                        BBAvatar(
                            name: member.name,
                            size: 48,
                            isSelected: selectedMember?.id == member.id
                        )

                        Text(firstName(member.name))
                            .font(BBFont.small)
                            .foregroundStyle(
                                selectedMember?.id == member.id
                                    ? BBColor.primaryText
                                    : BBColor.secondaryText
                            )

                        let memberTotal = vm.totalForMember(member)
                        Text(CurrencyFormatter.formatShort(memberTotal))
                            .font(BBFont.captionBold)
                            .foregroundStyle(BBColor.primaryText)
                    }
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedMember = member
                        }
                        HapticManager.selection()
                    }
                }
            }
            .padding(.horizontal, BBSpacing.lg)
        }
    }

    // MARK: - Item Row

    private func itemRow(_ item: LineItem) -> some View {
        Button {
            guard let member = selectedMember else { return }
            withAnimation(.snappy(duration: 0.15)) {
                vm.toggleAssignment(item: item, member: member)
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: BBSpacing.md) {
                let isAssigned = selectedMember.map { item.assignedTo.contains($0.id) } ?? false

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isAssigned ? BBColor.accent : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isAssigned ? BBColor.accent : BBColor.border, lineWidth: 1.5)
                        }

                    if isAssigned {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.primaryText)

                    if !item.assignedTo.isEmpty {
                        let names = vm.members
                            .filter { item.assignedTo.contains($0.id) }
                            .map { firstName($0.name) }
                            .joined(separator: ", ")
                        Text(names)
                            .font(BBFont.small)
                            .foregroundStyle(BBColor.secondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.formatShort(item.price))
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)

                    if item.assignedTo.count > 1 {
                        Text("\(CurrencyFormatter.formatShort(item.pricePerPerson))/ea")
                            .font(BBFont.small)
                            .foregroundStyle(BBColor.secondaryText)
                    }
                }
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Party games

    private var partyGamesRow: some View {
        Button {
            HapticManager.tap()
            nav.advance(.gamesHub)
        } label: {
            HStack(spacing: BBSpacing.md) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(BBColor.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("party games")
                        .font(BBFont.captionBold)
                        .foregroundStyle(BBColor.primaryText)
                    Text("same group & totals — play before tip / settle up")
                        .font(BBFont.small)
                        .foregroundStyle(BBColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.sm)
            .background(BBColor.cardSurface)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            let unassignedCount = vm.lineItems.filter { $0.assignedTo.isEmpty }.count

            HStack {
                VStack(alignment: .leading) {
                    if unassignedCount > 0 {
                        Text("\(unassignedCount) unassigned")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.error)
                    } else {
                        Text("all items assigned")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.success)
                    }
                }

                Spacer()

                BBButton(title: "set tip") {
                    HapticManager.tap()
                    nav.advance(.tip)
                }
                .frame(width: 160)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
        .background(BBColor.background)
    }

    private func firstName(_ name: String) -> String {
        name.components(separatedBy: " ").first ?? name
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.members = [
        PartyMember(name: "You", isCurrentUser: true),
        PartyMember(name: "Alex"),
        PartyMember(name: "Jordan"),
    ]
    vm.lineItems = [
        LineItem(name: "Margherita Pizza", price: 18.00),
        LineItem(name: "Caesar Salad", price: 14.00),
        LineItem(name: "Sparkling Water", quantity: 2, price: 8.00),
        LineItem(name: "Tiramisu", price: 12.00),
    ]
    vm.subtotal = 52.00
    vm.tax = 4.62

    return ItemAssignmentView()
        .environment(vm)
}
