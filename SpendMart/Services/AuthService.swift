import FirebaseAuth

final class AuthService {
    static let shared = AuthService(); private init() {}

    func signUp(email: String, password: String, displayName: String?) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        if let name = displayName, !name.isEmpty {
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
        }
        try await result.user.sendEmailVerification()
        return result.user
    }

    func signIn(email: String, password: String) async throws -> User {
        try await Auth.auth().signIn(withEmail: email, password: password).user
    }

    func reloadUser() async throws -> User {
        guard let user = Auth.auth().currentUser else { throw NSError(domain: "NoUser", code: 0) }
        try await user.reload()
        return user
    }

    func signOut() throws { try Auth.auth().signOut() }
}
