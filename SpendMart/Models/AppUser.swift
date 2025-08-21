import Foundation

struct AppUser: Codable, Identifiable {
    var id: String { uid }
    let uid: String
    let email: String
    var displayName: String?
    let createdAt: Date
    var updatedAt: Date

    init(uid: String, email: String, displayName: String? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toDict() -> [String: Any] {
        [
            "uid": uid,
            "email": email,
            "displayName": displayName as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}
