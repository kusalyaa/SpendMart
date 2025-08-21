import FirebaseFirestore

final class UserService {
    static let shared = UserService(); private init() {}
    private var users: CollectionReference { Firestore.firestore().collection("users") }

    func ensureUserDoc(_ user: AppUser) async throws {
        try await users.document(user.uid).setData(user.toDict(), merge: true)
    }
}
