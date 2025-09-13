import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if session.isLoggedIn {
                RootTabView()      // ← your main tabs
            } else {
                ContentView()      // ← your existing onboarding/login entry
            }
        }
        // Do not bounce to Login while pickers are active
        .onChange(of: scenePhase) { _, phase in
            guard !session.suppressAuthRouting else { return }
            if phase == .active {
                session.refreshUser() // safe, non-destructive
            }
        }
    }
}
