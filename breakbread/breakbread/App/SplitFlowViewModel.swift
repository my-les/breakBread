import SwiftUI

@Observable
class SplitFlowViewModel {
    var restaurant: Restaurant?
    var members: [PartyMember] = []
    var lineItems: [LineItem] = []
    var subtotal: Double = 0
    var tax: Double = 0
    var tipPreset: TipPreset = .twenty
    var customTipPercent: Double?
    /// JPEG/PNG (or other bitmap) bytes for the receipt preview and OCR.
    var receiptImageData: Data?
    var isProcessingReceipt = false
    var ocrError: String?
    var currentStep: SplitStep = .search
    var partyCount: Int = 2
    var isQuickTipFlow = false
    var payerMemberID: UUID?
    var requestStatuses: [UUID: PaymentRequestStatus] = [:]
    var restaurantMenu: [MenuSection] = []
    var isLoadingMenu = false

    enum SplitStep: Int, CaseIterable {
        case search = 0
        case menuPicker = 10
        case party = 1
        case scan = 2
        case review = 3
        case assign = 4
        case tip = 5
        case quickTip = 6
        case splitEven = 9
        case summary = 7
        case payment = 8
    }

    var tipPercent: Double {
        customTipPercent ?? tipPreset.rawValue
    }

    var tipAmount: Double {
        subtotal * tipPercent / 100
    }

    var total: Double {
        subtotal + tax + tipAmount
    }

    var isUsingCustomTip: Bool {
        customTipPercent != nil
    }

    func selectTipPreset(_ preset: TipPreset) {
        customTipPercent = nil
        tipPreset = preset
    }

    var payerMember: PartyMember? {
        guard let payerMemberID else { return nil }
        return members.first(where: { $0.id == payerMemberID })
    }

    var requestRecipients: [PartyMember] {
        members.filter { $0.id != payerMemberID }
    }

    func totalForMember(_ member: PartyMember) -> Double {
        let memberItems = lineItems.filter { $0.assignedTo.contains(member.id) }
        let itemTotal = memberItems.reduce(0.0) { sum, item in
            return sum + item.pricePerPerson
        }

        let hasAssignments = lineItems.contains { !$0.assignedTo.isEmpty }

        guard subtotal > 0, hasAssignments else {
            let evenShare = total / Double(max(members.count, 1))
            return evenShare
        }

        let proportion = itemTotal / subtotal
        let memberTax = tax * proportion
        let memberTip = tipAmount * proportion
        return itemTotal + memberTax + memberTip
    }

    func itemsForMember(_ member: PartyMember) -> [LineItem] {
        lineItems.filter { $0.assignedTo.contains(member.id) }
    }

    func toggleAssignment(item: LineItem, member: PartyMember) {
        guard let index = lineItems.firstIndex(where: { $0.id == item.id }) else { return }
        if lineItems[index].assignedTo.contains(member.id) {
            lineItems[index].assignedTo.remove(member.id)
        } else {
            lineItems[index].assignedTo.insert(member.id)
        }
    }

    func recalculateSubtotal() {
        subtotal = lineItems.reduce(0) { $0 + $1.price }
    }

    func addLineItem(name: String, price: Double, quantity: Int = 1) {
        let item = LineItem(name: name, quantity: quantity, price: price)
        lineItems.append(item)
        recalculateSubtotal()
    }

    func removeLineItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
        recalculateSubtotal()
    }

    func generateShareText() -> String {
        var text = "breakbread. split\n"
        if let name = restaurant?.name {
            text += "\(name)\n"
        }
        text += String(repeating: "-", count: 30) + "\n"
        for member in members {
            let amount = totalForMember(member)
            text += "\(member.name): $\(String(format: "%.2f", amount))\n"
        }
        text += String(repeating: "-", count: 30) + "\n"
        text += "total: $\(String(format: "%.2f", total))\n"
        text += "tip: \(Int(tipPercent))%\n"
        return text
    }

    func prepareQuickTipMembers(count: Int) {
        let safeCount = max(2, count)
        partyCount = safeCount
        members = [PartyMember(name: "You", isCurrentUser: true)]
        for index in 2...safeCount {
            members.append(PartyMember(name: "Person \(index)"))
        }
        if payerMemberID == nil {
            payerMemberID = members.first?.id
        }
    }

    func setPayer(_ member: PartyMember) {
        payerMemberID = member.id
        if requestStatuses[member.id] != nil {
            requestStatuses[member.id] = nil
        }
    }

    func requestStatus(for member: PartyMember) -> PaymentRequestStatus {
        requestStatuses[member.id] ?? .notSent
    }

    func markRequestSent(for member: PartyMember) {
        requestStatuses[member.id] = .sent
    }

    func markRequestPaid(for member: PartyMember) {
        requestStatuses[member.id] = .paid
    }

    var allRequestsSent: Bool {
        let recipients = requestRecipients
        guard !recipients.isEmpty else { return false }
        return recipients.allSatisfy { requestStatuses[$0.id] == .sent || requestStatuses[$0.id] == .paid }
    }

    func loadMenu(sections: [MenuSection]) {
        restaurantMenu = sections
    }

    var hasMenu: Bool {
        !restaurantMenu.isEmpty
    }

    func reset() {
        restaurant = nil
        members = []
        lineItems = []
        subtotal = 0
        tax = 0
        tipPreset = .twenty
        customTipPercent = nil
        restaurantMenu = []
        isLoadingMenu = false
        receiptImageData = nil
        isProcessingReceipt = false
        ocrError = nil
        currentStep = .search
        partyCount = 2
        isQuickTipFlow = false
        payerMemberID = nil
        requestStatuses = [:]
    }
}
