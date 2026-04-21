import SwiftUI

struct SplitSummaryView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "split summary", step: nil) {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    receiptCard
                    memberBreakdown
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.lg)
                .padding(.bottom, 100)
            }

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: vm.generateShareText())
        }
    }

    // MARK: - Receipt Card

    private var receiptCard: some View {
        BBCard {
            VStack(spacing: BBSpacing.md) {
                if let name = vm.restaurant?.name {
                    Text(name)
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                        .frame(maxWidth: .infinity)
                }

                Text(String(repeating: "-", count: 32))
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.border)

                ForEach(vm.lineItems) { item in
                    HStack {
                        Text(item.name)
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                        Spacer()
                        Text(CurrencyFormatter.formatShort(item.price))
                            .font(BBFont.body)
                            .foregroundStyle(BBColor.primaryText)
                    }
                }

                Text(String(repeating: "-", count: 32))
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.border)

                Group {
                    summaryRow("subtotal", CurrencyFormatter.formatShort(vm.subtotal))
                    summaryRow("tax", CurrencyFormatter.formatShort(vm.tax))
                    summaryRow("tip (\(Int(vm.tipPercent))%)", CurrencyFormatter.formatShort(vm.tipAmount))
                }

                Divider()

                HStack {
                    Text("total")
                        .font(BBFont.bodyBold)
                    Spacer()
                    Text(CurrencyFormatter.formatShort(vm.total))
                        .font(BBFont.heroNumber)
                }
                .foregroundStyle(BBColor.primaryText)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)
            Spacer()
            Text(value)
                .font(BBFont.body)
                .foregroundStyle(BBColor.primaryText)
        }
    }

    // MARK: - Member Breakdown

    private var memberBreakdown: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("each person owes")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            ForEach(vm.members) { member in
                memberCard(member)
            }
        }
    }

    private func memberCard(_ member: PartyMember) -> some View {
        let total = vm.totalForMember(member)
        let items = vm.itemsForMember(member)

        return BBCardOutlined {
            VStack(spacing: BBSpacing.sm) {
                HStack {
                    BBAvatar(name: member.name, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)
                        Text("\(items.count) items")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.secondaryText)
                    }

                    Spacer()

                    Text(CurrencyFormatter.formatShort(total))
                        .font(BBFont.sectionHeader)
                        .foregroundStyle(BBColor.primaryText)
                }

                if !items.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(items) { item in
                            HStack {
                                Text(item.name)
                                    .font(BBFont.caption)
                                    .foregroundStyle(BBColor.secondaryText)
                                Spacer()
                                Text(CurrencyFormatter.formatShort(item.pricePerPerson))
                                    .font(BBFont.caption)
                                    .foregroundStyle(BBColor.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: BBSpacing.sm) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 56, height: 56)
                        .foregroundStyle(BBColor.primaryText)
                        .background(BBColor.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                }

                BBButton(title: "request payment") {
                    HapticManager.tap()
                    nav.advance(.payment)
                }
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
        .background(BBColor.background)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.restaurant = Restaurant(id: "1", name: "Carbone", address: "181 Thompson St")
    vm.members = [
        PartyMember(name: "You", isCurrentUser: true),
        PartyMember(name: "Alex"),
    ]
    vm.lineItems = [
        LineItem(name: "Spicy Rigatoni", price: 32.00, assignedTo: [vm.members[0].id]),
        LineItem(name: "Veal Parm", price: 38.00, assignedTo: [vm.members[1].id]),
        LineItem(name: "Bread Basket", price: 12.00, assignedTo: Set(vm.members.map(\.id))),
    ]
    vm.subtotal = 82.00
    vm.tax = 7.28

    return SplitSummaryView().environment(vm)
}
