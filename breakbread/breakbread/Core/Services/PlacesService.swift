import Foundation
import CoreLocation

actor PlacesService {
    static let shared = PlacesService()

    private let apiKey: String
    private let baseURL = "https://places.googleapis.com/v1/places"

    init() {
        let plist = { (key: String) -> String? in
            Bundle.main.object(forInfoDictionaryKey: key) as? String
        }
        let envKey = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let plistKey = plist("GOOGLE_PLACES_API_KEY")?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let envKey, !envKey.isEmpty {
            apiKey = envKey
        } else if let plistKey, !plistKey.isEmpty {
            apiKey = plistKey
        } else {
            apiKey = ""
        }
    }

    nonisolated var isLiveSearchConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR_GOOGLE_PLACES_API_KEY"
    }

    func searchRestaurants(query: String, location: CLLocationCoordinate2D? = nil) async throws -> [Restaurant] {
        if query.isEmpty {
            return Array(sampleRestaurants.prefix(6))
        }

        // If no API key is configured, return sample data for development
        if !isLiveSearchConfigured {
            return sampleRestaurants.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        }

        let components = URLComponents(string: "\(baseURL):searchText")!
        let body: [String: Any] = [
            "textQuery": "\(query) restaurant",
            "maxResultCount": 10,
            "includedType": "restaurant"
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.displayName,places.formattedAddress,places.rating,places.priceLevel,places.photos,places.primaryType,places.location",
                        forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw PlacesServiceError.apiUnavailable
        }
        return try parseRestaurants(from: data)
    }

    func autocomplete(query: String) async throws -> [Restaurant] {
        try await searchRestaurants(query: query)
    }

    func fetchMenu(placeId: String) async throws -> [MenuSection] {
        guard isLiveSearchConfigured else { return [] }

        let url = URL(string: "\(baseURL)/\(placeId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("displayName,businessMenus", forHTTPHeaderField: "X-Goog-FieldMask")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            return []
        }

        return parseMenu(from: data)
    }

    private func parseMenu(from data: Data) -> [MenuSection] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let menus = json["businessMenus"] as? [[String: Any]]
        else {
            return []
        }

        var sections: [MenuSection] = []

        for menu in menus {
            guard let menuSections = menu["sections"] as? [[String: Any]] else { continue }

            for section in menuSections {
                let sectionName = (section["name"] as? [String: Any])?["text"] as? String
                    ?? section["name"] as? String
                    ?? "Menu"

                guard let items = section["items"] as? [[String: Any]] else { continue }

                let menuItems: [MenuItem] = items.compactMap { item in
                    let itemName = (item["name"] as? [String: Any])?["text"] as? String
                        ?? item["name"] as? String
                        ?? ""
                    guard !itemName.isEmpty else { return nil }

                    let description = (item["description"] as? [String: Any])?["text"] as? String
                        ?? item["description"] as? String

                    var price: Double = 0
                    if let priceObj = item["price"] as? [String: Any] {
                        if let units = priceObj["units"] as? String, let val = Double(units) {
                            price = val
                        } else if let units = priceObj["units"] as? Int {
                            price = Double(units)
                        }
                        if let nanos = priceObj["nanos"] as? Int {
                            price += Double(nanos) / 1_000_000_000
                        }
                    }

                    return MenuItem(name: itemName, description: description, price: price)
                }

                if !menuItems.isEmpty {
                    sections.append(MenuSection(name: sectionName, items: menuItems))
                }
            }
        }

        return sections
    }
}

enum PlacesServiceError: LocalizedError {
    case apiUnavailable

    var errorDescription: String? {
        switch self {
        case .apiUnavailable:
            return "Restaurant search API is unavailable right now."
        }
    }
}

// MARK: - Sample Data

extension PlacesService {
    private func parseRestaurants(from data: Data) throws -> [Restaurant] {
        guard
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let places = jsonObject["places"] as? [[String: Any]]
        else {
            return []
        }

        return places.map { place in
            let displayName = (place["displayName"] as? [String: Any])?["text"] as? String ?? ""
            let formattedAddress = place["formattedAddress"] as? String ?? ""
            let primaryType = place["primaryType"] as? String ?? "restaurant"
            let rating = place["rating"] as? Double ?? 0
            let placeName = place["name"] as? String ?? UUID().uuidString
            let photoReference = ((place["photos"] as? [[String: Any]])?.first)?["name"] as? String
            let location = place["location"] as? [String: Any]
            let latitude = location?["latitude"] as? Double ?? 0
            let longitude = location?["longitude"] as? Double ?? 0
            let priceLevelRaw = place["priceLevel"] as? String

            return Restaurant(
                id: placeName,
                name: displayName,
                address: formattedAddress,
                category: primaryType,
                priceLevel: mapPriceLevel(priceLevelRaw),
                rating: rating,
                photoReference: photoReference,
                latitude: latitude,
                longitude: longitude
            )
        }
    }

    private func mapPriceLevel(_ value: String?) -> Int {
        switch value {
        case "PRICE_LEVEL_FREE": return 0
        case "PRICE_LEVEL_INEXPENSIVE": return 1
        case "PRICE_LEVEL_MODERATE": return 2
        case "PRICE_LEVEL_EXPENSIVE": return 3
        case "PRICE_LEVEL_VERY_EXPENSIVE": return 4
        default: return 0
        }
    }

    var sampleRestaurants: [Restaurant] {
        [
            Restaurant(id: "1", name: "Nobu", address: "105 Hudson St, New York, NY", category: "Japanese", priceLevel: 4, rating: 4.5),
            Restaurant(id: "2", name: "Carbone", address: "181 Thompson St, New York, NY", category: "Italian", priceLevel: 4, rating: 4.7),
            Restaurant(id: "3", name: "Sweetgreen", address: "1164 Broadway, New York, NY", category: "Salads", priceLevel: 2, rating: 4.2),
            Restaurant(id: "4", name: "Joe's Pizza", address: "7 Carmine St, New York, NY", category: "Pizza", priceLevel: 1, rating: 4.6),
            Restaurant(id: "5", name: "Le Bernardin", address: "155 W 51st St, New York, NY", category: "French", priceLevel: 4, rating: 4.8),
            Restaurant(id: "6", name: "Shake Shack", address: "691 8th Ave, New York, NY", category: "Burgers", priceLevel: 2, rating: 4.3),
            Restaurant(id: "7", name: "Tatiana", address: "10 Lincoln Center Plz, New York, NY", category: "American", priceLevel: 3, rating: 4.6),
            Restaurant(id: "8", name: "Thai Diner", address: "186 Mott St, New York, NY", category: "Thai", priceLevel: 2, rating: 4.4),
            Restaurant(id: "9", name: "Russ & Daughters", address: "179 E Houston St, New York, NY", category: "Deli", priceLevel: 2, rating: 4.7),
            Restaurant(id: "10", name: "Los Tacos No. 1", address: "75 9th Ave, New York, NY", category: "Mexican", priceLevel: 1, rating: 4.5),
        ]
    }
}
