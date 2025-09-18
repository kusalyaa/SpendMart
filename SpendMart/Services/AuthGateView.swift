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
                LoginView()
                    .onAppear {  }

            case .verify(let email):
                ConfirmEmailView(
                    userEmail: email,
                    onVerified: {
                        Task { await refreshAndRoute() }
                    },
                    onChangeEmail: {
                        Task { await signOutAndGoLogin() }
                    }
                )

            case .dashboard:
                DashboardView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            
            Task { await refreshAndRoute() }
        }
    }

    
    private func refreshAndRoute() async {
        if let user = Auth.auth().currentUser {
            do {
                try await user.reload() 
            } catch {
                
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
        do { try Auth.auth().signOut() } catch { }
        await MainActor.run { route = .login }
    }
}
