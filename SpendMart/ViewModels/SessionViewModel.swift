
import Foundation
import FirebaseAuth

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var firebaseUser: User?
    @Published var isEmailVerified = false

    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { await self?.handleAuthChange(user) }
        }
    }

    deinit {
        if let h = listener { Auth.auth().removeStateDidChangeListener(h) }
    }

    private func handleAuthChange(_ user: User?) async {
        guard let user else {
            firebaseUser = nil
            isEmailVerified = false
            return
        }
        do {
            try await user.reload()
            let fresh = Auth.auth().currentUser
            firebaseUser = fresh
            isEmailVerified = fresh?.isEmailVerified ?? false
        } catch {
            firebaseUser = user
            isEmailVerified = user.isEmailVerified
        }
    }

    func refreshVerification() async {
        guard let u = Auth.auth().currentUser else { return }
        do {
            try await u.reload()
            isEmailVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        } catch { /* swallow */ }
    }

    func signOut() {
        try? Auth.auth().signOut()
        firebaseUser = nil
        isEmailVerified = false
    }
}
