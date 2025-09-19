import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appLockUnlocked") private var unlocked: Bool = false
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
    @State private var didCheckColdLaunch = false

    // Keep/adjust this as you like; gate biometrics only for logged-in users
    private var requiresBiometricGate: Bool {
        session.isLoggedIn
    }

    private func log(_ msg: String, file: StaticString = #fileID, line: Int = #line) {
        print("[Flow][AppRootView] \(msg)  (\(file):\(line))")
    }

    var body: some View {
        Group {
            // 🚧 Freeze routing while onboarding views are active
            if session.suppressAuthRouting {
                ContentView()
                    .onAppear { log("Presenting ContentView (login/onboarding) | suppressAuthRouting=true | onboardingComplete=\(onboardingComplete)") }

            // Not logged in → login/onboarding container
            } else if !session.isLoggedIn {
                ContentView()
                    .onAppear { log("Presenting ContentView (login/onboarding) | unlocked=\(unlocked) | suppressAuthRouting=false | onboardingComplete=\(onboardingComplete)") }

            // Logged in but onboarding NOT complete → keep showing onboarding container
            } else if !onboardingComplete {
                ContentView()
                    .onAppear { log("Presenting ContentView (onboarding) | loggedIn | onboardingComplete=false") }

            // Logged in, onboarding done, but still locked → biometric gate
            } else if requiresBiometricGate && !unlocked {
                BiometricGateView {
                    log("BiometricGateView success → unlocked=true")
                    unlocked = true
                }
                .onAppear {
                    log("Presenting BiometricGateView | isLoggedIn=\(session.isLoggedIn) | unlocked=\(unlocked)")
                }

            // ✅ All clear → Home
            } else {
                RootTabView()
                    .onAppear { log("Presenting RootTabView | unlocked=\(unlocked) | onboardingComplete=\(onboardingComplete)") }
            }
        }
        .onAppear {
            log("onAppear | cold=\(didCheckColdLaunch==false) | isLoggedIn=\(session.isLoggedIn) | requiresBiometricGate=\(requiresBiometricGate) | unlocked=\(unlocked) | onboardingComplete=\(onboardingComplete)")
            if !didCheckColdLaunch && requiresBiometricGate {
                didCheckColdLaunch = true
                // Optional: relock at cold launch
                unlocked = false
                log("Cold launch → relock (unlocked=false)")
            }
        }
        .onChange(of: scenePhase) { phase in
            log("scenePhase changed → \(phase) | suppressAuthRouting=\(session.suppressAuthRouting) | onboardingComplete=\(onboardingComplete)")
            guard !session.suppressAuthRouting else { return } // don’t thrash routing mid-onboarding
            if phase == .active {
                log(".active → session.refreshUser() (no unlock changes here)")
                session.refreshUser()
            }
        }
    }
}
