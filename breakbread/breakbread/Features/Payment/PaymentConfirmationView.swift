import SwiftUI
import SwiftData

struct PaymentConfirmationView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.dismissSplitFlow) private var dismissFlow
    @Environment(\.modelContext) private var modelContext

    @State private var checkmarkScale: CGFloat = 0
    @State private var hasPersistedSplit = false

    var body: some View {
        VStack(spacing: BBSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(BBColor.success.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(BBColor.success)
                    .frame(width: 80, height: 80)
                    .scaleEffect(checkmarkScale)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(checkmarkScale)
            }

            VStack(spacing: BBSpacing.sm) {
                Text("you're all set!")
                    .font(BBFont.title)
                    .foregroundStyle(BBColor.primaryText)

                if let name = vm.restaurant?.name {
                    Text(name)
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.secondaryText)
                }

                Text(CurrencyFormatter.formatShort(vm.total))
                    .font(BBFont.heroNumber)
                    .foregroundStyle(BBColor.primaryText)
                    .padding(.top, BBSpacing.sm)

                Text("split \(vm.members.count) ways")
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
            }

            Spacer()

            VStack(spacing: BBSpacing.sm) {
                BBButton(title: "done") {
                    HapticManager.success()
                    dismissFlow()
                }

                Button("split again") {
                    vm.reset()
                    dismissFlow()
                }
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1
            }
            HapticManager.success()
            persistSplitIfNeeded()
        }
    }

    private func persistSplitIfNeeded() {
        guard !hasPersistedSplit else { return }

        let split = SavedSplit(
            restaurantName: vm.restaurant?.name,
            restaurantPlaceId: vm.restaurant?.id,
            total: vm.total,
            tipPercent: vm.tipPercent,
            memberCount: vm.members.count,
            userShare: vm.totalForMember(vm.payerMember ?? vm.members.first ?? PartyMember(name: "You")),
            createdAt: .now
        )

        split.setLineItems(vm.lineItems)
        split.setMembers(vm.members)
        modelContext.insert(split)

        autoSaveParty()
        saveCrowdsourcedMenuItems()
        hasPersistedSplit = true
    }

    private func saveCrowdsourcedMenuItems() {
        guard let placeId = vm.restaurant?.id,
              let restaurantName = vm.restaurant?.name,
              !vm.lineItems.isEmpty else { return }

        let descriptor = FetchDescriptor<CrowdsourcedMenuItem>(
            predicate: #Predicate { $0.placeId == placeId }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        for item in vm.lineItems {
            let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanName.isEmpty, item.price > 0 else { continue }

            if let match = existing.first(where: {
                $0.itemName.lowercased() == cleanName.lowercased()
            }) {
                match.timesOrdered += 1
                match.lastSeen = .now
                if item.price > 0 { match.price = item.price }
            } else {
                let newItem = CrowdsourcedMenuItem(
                    placeId: placeId,
                    restaurantName: restaurantName,
                    itemName: cleanName,
                    price: item.price
                )
                modelContext.insert(newItem)
            }
        }
    }

    private func autoSaveParty() {
        let realMembers = vm.members.filter {
            !$0.name.hasPrefix("Person ") && $0.name != "You"
        }
        guard realMembers.count >= 1 else { return }

        let partyName = vm.restaurant?.name ?? "Party"
        let party = SavedParty(name: partyName)
        party.setMembers(vm.members)
        party.lastUsed = .now
        modelContext.insert(party)
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.restaurant = Restaurant(id: "1", name: "Carbone", address: "")
    vm.members = [
        PartyMember(name: "You", isCurrentUser: true),
        PartyMember(name: "Alex"),
    ]
    vm.subtotal = 82.00
    vm.tax = 7.28

    return PaymentConfirmationView().environment(vm)
}
