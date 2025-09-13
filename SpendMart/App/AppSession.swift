import SwiftUI
import FirebaseAuth

@MainActor
final class AppSession: ObservableObject {
    @Published var isLoggedIn: Bool = (Auth.auth().currentUser != nil)
    @Published var isEmailVerified: Bool = (Auth.auth().currentUser?.isEmailVerified ?? false)

    /// When true, routers must not flip the UI (used while system pickers are presented).
    @Published var suppressAuthRouting: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                self.isLoggedIn = (user != nil)
                self.isEmailVerified = user?.isEmailVerified ?? false
                print("[Session] Auth changed → \(user?.uid ?? "nil")")
            }
        }
    }

    deinit { if let h = handle { Auth.auth().removeStateDidChangeListener(h) } }

    func refreshUser() {
        guard let u = Auth.auth().currentUser else { return }
        u.reload { _ in
            Task { @MainActor in
                self.isEmailVerified = Auth.auth().currentUser?.isEmailVerified ?? false
            }
        }
    }
}
