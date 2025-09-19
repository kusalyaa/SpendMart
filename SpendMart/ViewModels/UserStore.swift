
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct UserFlags: Codable {
    var hasCompletedIncomeSetup: Bool
}

struct UserDoc: Codable {
    var uid: String
    var email: String
    var displayName: String?
    var flags: UserFlags?

    init(dict: [String: Any]) {
        uid = dict["uid"] as? String ?? ""
        email = dict["email"] as? String ?? ""
        displayName = dict["displayName"] as? String
        if let f = dict["flags"] as? [String: Any] {
            flags = UserFlags(hasCompletedIncomeSetup: (f["hasCompletedIncomeSetup"] as? Bool) ?? false)
        } else {
            flags = nil
        }
    }
}

@MainActor
final class UserStore: ObservableObject {
    @Published var userDoc: UserDoc?
    private var sub: ListenerRegistration?

    func bind(uid: String) {
        sub?.remove()
        let ref = Firestore.firestore().collection("users").document(uid)
        sub = ref.addSnapshotListener { [weak self] snap, _ in
            guard let data = snap?.data() else { return }
            self?.userDoc = UserDoc(dict: data)
        }
    }

    func markIncomeSetupDone(uid: String) {
        let ref = Firestore.firestore().collection("users").document(uid)
        ref.setData(["flags": ["hasCompletedIncomeSetup": true]], merge: true)
    }

    deinit { sub?.remove() }
}
