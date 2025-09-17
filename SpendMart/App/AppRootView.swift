import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    // Persisted flag for this run
    @AppStorage("appLockUnlocked") private var unlocked: Bool = false
    @State private var didCheckColdLaunch = false

    var body: some View {
        Group {
            if session.isLoggedIn {
                if requiresBiometricGate && !unlocked {
                    BiometricGateView {
                        unlocked = true
                    }
                } else {
                    RootTabView()
                        .onChange(of: session.isLoggedIn) { loggedIn in
                            // Correct syntax: single parameter
                            if loggedIn {
                                // If user logged in right now, skip Face ID this run
                                unlocked = true
                            } else {
                                unlocked = false
                            }
                        }
                }
            } else {
                ContentView()
                    .onAppear {
                        // Ensure gate resets in login/onboarding
                        unlocked = false
                    }
            }
        }
        .onAppear {
            // Cold launch: require Face ID if already logged in
            if !didCheckColdLaunch {
                didCheckColdLaunch = true
                if session.isLoggedIn && requiresBiometricGate {
                    unlocked = false
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            guard !session.suppressAuthRouting else { return }
            if phase == .active {
                // Only refresh, do not re-lock
                session.refreshUser()
            } else if phase == .background {
                // Re-lock when app goes to background
                if session.isLoggedIn && requiresBiometricGate {
                    unlocked = false
                }
            }
        }
    }

    private var requiresBiometricGate: Bool {
        switch BiometricAuth.available() {
        case .faceID, .touchID: return true
        case .none:             return false
        }
    }
}
