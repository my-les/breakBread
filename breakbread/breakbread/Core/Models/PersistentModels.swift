import Foundation
import SwiftData

@Model
class SavedSplit {
    @Attribute(.unique) var id: UUID
    var restaurantName: String?
    var restaurantPlaceId: String?
    var total: Double
    var tipPercent: Double
    var memberCount: Int
    var userShare: Double
    var createdAt: Date
    var lineItemsJSON: Data?
    var membersJSON: Data?

    init(
        id: UUID = UUID(),
        restaurantName: String? = nil,
        restaurantPlaceId: String? = nil,
        total: Double = 0,
        tipPercent: Double = 20,
        memberCount: Int = 1,
        userShare: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.restaurantName = restaurantName
        self.restaurantPlaceId = restaurantPlaceId
        self.total = total
        self.tipPercent = tipPercent
        self.memberCount = memberCount
        self.userShare = userShare
        self.createdAt = createdAt
    }

    func setLineItems(_ items: [LineItem]) {
        lineItemsJSON = try? JSONEncoder().encode(items)
    }

    func getLineItems() -> [LineItem] {
        guard let data = lineItemsJSON else { return [] }
        return (try? JSONDecoder().decode([LineItem].self, from: data)) ?? []
    }

    func setMembers(_ members: [PartyMember]) {
        membersJSON = try? JSONEncoder().encode(members)
    }

    func getMembers() -> [PartyMember] {
        guard let data = membersJSON else { return [] }
        return (try? JSONDecoder().decode([PartyMember].self, from: data)) ?? []
    }
}

@Model
class SavedParty {
    @Attribute(.unique) var id: UUID
    var name: String
    var membersJSON: Data?
    var createdAt: Date
    var lastUsed: Date

    init(id: UUID = UUID(), name: String = "", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsed = createdAt
    }

    func setMembers(_ members: [PartyMember]) {
        membersJSON = try? JSONEncoder().encode(members)
    }

    func getMembers() -> [PartyMember] {
        guard let data = membersJSON else { return [] }
        return (try? JSONDecoder().decode([PartyMember].self, from: data)) ?? []
    }
}

@Model
class CrowdsourcedMenuItem {
    var placeId: String
    var restaurantName: String
    var itemName: String
    var price: Double
    var timesOrdered: Int
    var lastSeen: Date

    init(placeId: String, restaurantName: String, itemName: String, price: Double) {
        self.placeId = placeId
        self.restaurantName = restaurantName
        self.itemName = itemName
        self.price = price
        self.timesOrdered = 1
        self.lastSeen = .now
    }
}

@Model
class FavoriteRestaurant {
    @Attribute(.unique) var placeId: String
    var name: String
    var address: String
    var category: String
    var priceLevel: Int
    var rating: Double
    var addedAt: Date

    init(restaurant: Restaurant) {
        self.placeId = restaurant.id
        self.name = restaurant.name
        self.address = restaurant.address
        self.category = restaurant.category
        self.priceLevel = restaurant.priceLevel
        self.rating = restaurant.rating
        self.addedAt = .now
    }

    func toRestaurant() -> Restaurant {
        Restaurant(
            id: placeId,
            name: name,
            address: address,
            category: category,
            priceLevel: priceLevel,
            rating: rating
        )
    }
}

@Model
class WishlistRestaurant {
    @Attribute(.unique) var placeId: String
    var name: String
    var address: String
    var category: String
    var city: String
    var addedAt: Date

    init(restaurant: Restaurant, city: String = "") {
        self.placeId = restaurant.id
        self.name = restaurant.name
        self.address = restaurant.address
        self.category = restaurant.category
        self.city = city
        self.addedAt = .now
    }
}
