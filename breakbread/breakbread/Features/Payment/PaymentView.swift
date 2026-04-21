import SwiftUI

struct PaymentView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var selectedMethod: RequestMethod = .venmo
    @State private var selectedPayerID: UUID?
    @State private var showReminderOptions: UUID?

    private var payer: PartyMember? {
        vm.members.first(where: { $0.id == selectedPayerID })
    }

    private var requestRecipients: [PartyMember] {
        vm.members.filter { $0.id != selectedPayerID }
    }

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "settle up", step: nil) {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            ScrollView {
                VStack(spacing: BBSpacing.xl) {
                    payerSection
                    requestMethodSection
                    requestsSection
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.top, BBSpacing.lg)
                .padding(.bottom, 100)
            }

            bottomBar
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onAppear {
            if selectedPayerID == nil {
                let defaultPayer = vm.members.first(where: { $0.isCurrentUser }) ?? vm.members.first
                selectedPayerID = defaultPayer?.id
                if let defaultPayer {
                    vm.setPayer(defaultPayer)
                }
            }
        }
    }

    // MARK: - Payer Selector

    private var payerSection: some View {
        BBCard {
            VStack(alignment: .leading, spacing: BBSpacing.md) {
                Text("who paid the restaurant?")
                    .font(BBFont.captionBold)
                    .foregroundStyle(BBColor.secondaryText)
                    .tracking(1)

                Menu {
                    ForEach(vm.members) { member in
                        Button(member.name) {
                            selectedPayerID = member.id
                            vm.setPayer(member)
                            HapticManager.selection()
                        }
                    }
                } label: {
                    HStack(spacing: BBSpacing.md) {
                        if let payer {
                            BBAvatar(name: payer.name, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(payer.name)
                                    .font(BBFont.bodyBold)
                                    .foregroundStyle(BBColor.primaryText)
                                Text("collecting from others")
                                    .font(BBFont.caption)
                                    .foregroundStyle(BBColor.secondaryText)
                            }
                        } else {
                            Text("select payer")
                                .font(BBFont.body)
                                .foregroundStyle(BBColor.secondaryText)
                        }

                        Spacer()

                        Text(CurrencyFormatter.formatShort(vm.total))
                            .font(BBFont.bodyBold)
                            .foregroundStyle(BBColor.primaryText)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BBColor.secondaryText)
                    }
                    .padding(.horizontal, BBSpacing.md)
                    .frame(height: 52)
                    .background(BBColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: BBRadius.md)
                            .strokeBorder(BBColor.border, lineWidth: 1)
                    }
                }
            }
        }
    }

    // MARK: - Request Method

    private var requestMethodSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("send requests via")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BBSpacing.sm) {
                    ForEach(RequestMethod.allCases) { method in
                        methodChip(method)
                    }
                }
            }
        }
    }

    private func methodChip(_ method: RequestMethod) -> some View {
        let isSelected = selectedMethod == method

        return Button {
            selectedMethod = method
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: method.icon)
                    .font(.system(size: 14))
                Text(method.rawValue)
                    .font(BBFont.captionBold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? BBColor.onAccent : BBColor.primaryText)
            .background(isSelected ? BBColor.accent : BBColor.cardSurface)
            .clipShape(Capsule())
        }
    }

    // MARK: - Requests List

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: BBSpacing.md) {
            Text("requests")
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.secondaryText)
                .tracking(1)

            if requestRecipients.isEmpty {
                BBCard {
                    Text("select who paid to see who owes")
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(requestRecipients) { member in
                    requestRow(member)
                }
            }
        }
    }

    private func requestRow(_ member: PartyMember) -> some View {
        let status = vm.requestStatus(for: member)
        let amount = vm.totalForMember(member)

        return VStack(spacing: 0) {
            HStack(spacing: BBSpacing.md) {
                BBAvatar(name: member.name, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.primaryText)
                    Text(statusLabel(status))
                        .font(BBFont.caption)
                        .foregroundStyle(statusColor(status))
                }

                Spacer()

                Text(CurrencyFormatter.formatShort(amount))
                    .font(BBFont.bodyBold)
                    .foregroundStyle(BBColor.primaryText)

                actionButtons(for: member, status: status)
            }
            .padding(BBSpacing.md)

            if status == .sent && showReminderOptions == member.id {
                reminderOptions(for: member, amount: amount)
            }
        }
        .background(BBColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
    }

    @ViewBuilder
    private func actionButtons(for member: PartyMember, status: PaymentRequestStatus) -> some View {
        switch status {
        case .notSent:
            Button("send") {
                sendRequest(to: member)
            }
            .font(BBFont.captionBold)
            .foregroundStyle(BBColor.onAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BBColor.accent)
            .clipShape(Capsule())

        case .sent:
            HStack(spacing: 6) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        showReminderOptions = showReminderOptions == member.id ? nil : member.id
                    }
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(BBColor.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(BBColor.background)
                        .clipShape(Circle())
                        .overlay {
                            Circle().strokeBorder(BBColor.border, lineWidth: 1)
                        }
                }

                Button("settled") {
                    withAnimation(.snappy(duration: 0.2)) {
                        vm.markRequestPaid(for: member)
                        ReminderService.shared.cancelReminder(for: member.name)
                    }
                    HapticManager.success()
                }
                .font(BBFont.captionBold)
                .foregroundStyle(BBColor.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BBColor.background)
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(BBColor.border, lineWidth: 1)
                }
            }

        case .paid:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(BBColor.success)
        }
    }

    private func reminderOptions(for member: PartyMember, amount: Double) -> some View {
        HStack(spacing: BBSpacing.sm) {
            Text("remind:")
                .font(BBFont.caption)
                .foregroundStyle(BBColor.secondaryText)

            reminderButton("1h", minutes: 60, member: member, amount: amount)
            reminderButton("tomorrow", minutes: 1440, member: member, amount: amount)
            reminderButton("daily", minutes: -1, member: member, amount: amount)
        }
        .padding(.horizontal, BBSpacing.md)
        .padding(.bottom, BBSpacing.md)
    }

    private func reminderButton(_ label: String, minutes: Int, member: PartyMember, amount: Double) -> some View {
        Button(label) {
            Task {
                let granted = await ReminderService.shared.requestPermission()
                if granted {
                    if minutes == -1 {
                        ReminderService.shared.scheduleDailyReminder(
                            for: member.name,
                            amount: amount,
                            restaurantName: vm.restaurant?.name
                        )
                    } else {
                        ReminderService.shared.scheduleReminder(
                            for: member.name,
                            amount: amount,
                            restaurantName: vm.restaurant?.name,
                            delayMinutes: minutes
                        )
                    }
                    HapticManager.tap()
                    withAnimation { showReminderOptions = nil }
                }
            }
        }
        .font(BBFont.small)
        .foregroundStyle(BBColor.onAccent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(BBColor.accent)
        .clipShape(Capsule())
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        let allSettled = !requestRecipients.isEmpty && requestRecipients.allSatisfy { vm.requestStatus(for: $0) == .paid }

        return VStack(spacing: 0) {
            Divider()
            BBButton(title: allSettled ? "done — all settled!" : "finish", isDisabled: selectedPayerID == nil) {
                HapticManager.success()
                ReminderService.shared.cancelAllReminders()
                nav.advance(.confirmation)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
        .background(BBColor.background)
    }

    // MARK: - Helpers

    private func statusLabel(_ status: PaymentRequestStatus) -> String {
        switch status {
        case .notSent: return "not sent"
        case .sent: return "pending"
        case .paid: return "settled"
        }
    }

    private func statusColor(_ status: PaymentRequestStatus) -> Color {
        switch status {
        case .notSent: return BBColor.secondaryText
        case .sent: return BBColor.accent
        case .paid: return BBColor.success
        }
    }

    private func sendRequest(to member: PartyMember) {
        let amount = vm.totalForMember(member)
        let note = "breakbread split — \(vm.restaurant?.name ?? "dinner")"

        switch selectedMethod {
        case .venmo:
            let username = member.name.replacingOccurrences(of: " ", with: "").lowercased()
            PaymentService.shared.openVenmo(username: username, amount: amount, note: note)
        case .cashApp:
            let username = "$" + member.name.replacingOccurrences(of: " ", with: "").lowercased()
            PaymentService.shared.openCashApp(username: username, amount: amount)
        case .iMessage:
            PaymentService.shared.openIMessage(amount: amount, note: note)
        case .other:
            PaymentService.shared.shareRequest(amount: amount, note: note)
        }

        vm.markRequestSent(for: member)
        HapticManager.tap()
    }
}

#Preview {
    let vm = SplitFlowViewModel()
    vm.restaurant = Restaurant(id: "1", name: "Carbone", address: "181 Thompson St")
    vm.members = [
        PartyMember(name: "You", isCurrentUser: true),
        PartyMember(name: "Alex"),
        PartyMember(name: "Jordan"),
    ]
    vm.subtotal = 82.00
    vm.tax = 7.28

    return PaymentView().environment(vm)
}
