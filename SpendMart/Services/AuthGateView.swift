import SwiftUI
import FirebaseAuth

enum AppRoute {
    case checking
    case login
    case verify(email: String?)
    case dashboard
}

struct AuthGateView: View {
    @State private var route: AppRoute = .checking

    var body: some View {
        Group {
            switch route {
            case .checking:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Checking session…").foregroundColor(.secondary)
                }
                .onAppear { Task { await refreshAndRoute() } }

            case .login:
                LoginView() // your existing login screen
                    .onAppear { /* optional: cleanup UI state */ }

            case .verify(let email):
                ConfirmEmailView(
                    userEmail: email,
                    onVerified: {
                        Task { await refreshAndRoute() }   // re-check, then go dashboard
                    },
                    onChangeEmail: {
                        Task { await signOutAndGoLogin() } // allow changing email
                    }
                )

            case .dashboard:
                DashboardView() // <-- your real home screen
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // If the app returns from Mail/Safari, re-check verification automatically
            Task { await refreshAndRoute() }
        }
    }

    // Re-evaluate auth + verification and set the route
    private func refreshAndRoute() async {
        if let user = Auth.auth().currentUser {
            do {
                try await user.reload() // get fresh isEmailVerified
            } catch {
                // if reload fails transiently, keep previous route
            }
            if Auth.auth().currentUser?.isEmailVerified == true {
                await MainActor.run { route = .dashboard }
            } else {
                await MainActor.run { route = .verify(email: user.email) }
            }
        } else {
            await MainActor.run { route = .login }
        }
    }

    private func signOutAndGoLogin() async {
        do { try Auth.auth().signOut() } catch { /* ignore */ }
        await MainActor.run { route = .login }
    }
}
