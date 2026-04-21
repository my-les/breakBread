import Foundation

// MARK: - Line Item

struct LineItem: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var quantity: Int = 1
    var price: Double
    var assignedTo: Set<UUID> = []

    var pricePerPerson: Double {
        guard !assignedTo.isEmpty else { return price }
        return price / Double(assignedTo.count)
    }
}

// MARK: - Party Member

struct PartyMember: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var phoneNumber: String?
    var initial: String { String(name.prefix(1)).uppercased() }
    var isCurrentUser: Bool = false
}

// MARK: - Restaurant

struct Restaurant: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var address: String
    var category: String = ""
    var priceLevel: Int = 0
    var rating: Double = 0
    var photoReference: String?
    var latitude: Double = 0
    var longitude: Double = 0

    var priceLevelString: String {
        String(repeating: "$", count: max(priceLevel, 1))
    }
}

// MARK: - Menu Section (from Google Places)

struct MenuSection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let items: [MenuItem]
}

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String?
    let price: Double
}

// MARK: - Split Status

enum SplitStatus: String, Codable {
    case draft
    case scanning
    case reviewing
    case assigning
    case tipping
    case summary
    case settling
    case settled
}

enum PaymentRequestStatus: String, Codable {
    case notSent
    case sent
    case paid
}

// MARK: - Tip Preset

enum TipPreset: Double, CaseIterable, Identifiable {
    case fifteen = 15
    case eighteen = 18
    case twenty = 20
    case twentyFive = 25

    var id: Double { rawValue }
    var label: String { "\(Int(rawValue))%" }
}
