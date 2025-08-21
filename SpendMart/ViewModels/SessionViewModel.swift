import FirebaseAuth
import SwiftUI   // <-- add this if missing

@MainActor
final class SessionViewModel: ObservableObject {   // <-- must conform here
    @Published var currentUser: AppUser?
    @Published var isEmailVerified = false

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { await self?.onAuthChange(user) }
        }
    }

    private func onAuthChange(_ user: User?) async {
        guard let user else {
            currentUser = nil
            isEmailVerified = false
            return
        }
        let appUser = AppUser(uid: user.uid, email: user.email ?? "", displayName: user.displayName)
        do { try await UserService.shared.ensureUserDoc(appUser) } catch { }
        currentUser = appUser
        isEmailVerified = user.isEmailVerified
    }
}
