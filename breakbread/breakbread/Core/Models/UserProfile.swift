import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var displayName: String
    var email: String?
    var phoneNumber: String?
    var avatarURL: String?
    var venmoUsername: String?
    var cashAppUsername: String?
    var createdAt: Date

    var initial: String { String(displayName.prefix(1)).uppercased() }

    static let guest = UserProfile(
        id: "guest",
        displayName: "You",
        createdAt: .now
    )
}
