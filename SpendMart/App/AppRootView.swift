import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appLockUnlocked") private var unlocked: Bool = false
    @State private var didCheckColdLaunch = false

    private var requiresBiometricGate: Bool {
        // your original gate condition; keeping it simple here
        return true
    }

    private func log(_ msg: String, file: StaticString = #fileID, line: Int = #line) {
        print("[Flow][AppRootView] \(msg)  (\(file):\(line))")
    }

    var body: some View {
        Group {
            // 🚧 1) Freeze routing while onboarding is running
            if session.suppressAuthRouting {
                ContentView()
                    .onAppear { log("Presenting ContentView (login/onboarding) | suppressAuthRouting=true") }

            } else if requiresBiometricGate && !unlocked && session.isLoggedIn {
                BiometricGateView {
                    log("BiometricGateView success → unlocked=true")
                    unlocked = true
                }
                .onAppear {
                    log("Presenting BiometricGateView (pre-content) | isLoggedIn=\(session.isLoggedIn) | unlocked=\(unlocked)")
                }

            } else if !session.isLoggedIn {
                ContentView()
                    .onAppear { log("Presenting ContentView (login/onboarding) | unlocked=\(unlocked) | suppressAuthRouting=false") }

            } else {
                RootTabView()
                    .onAppear { log("Presenting RootTabView | unlocked=\(unlocked)") }
            }
        }
        .onAppear {
            log("onAppear | didCheckColdLaunch=\(didCheckColdLaunch) | isLoggedIn=\(session.isLoggedIn) | requiresBiometricGate=\(requiresBiometricGate) | unlocked=\(unlocked)")
            if !didCheckColdLaunch && requiresBiometricGate {
                didCheckColdLaunch = true
                // optional: relock on cold start
                unlocked = false
                log("Cold launch → relock (unlocked=false)")
            }
        }
        .onChange(of: scenePhase) { phase in
            log("scenePhase changed → \(phase) | suppressAuthRouting=\(session.suppressAuthRouting)")
            guard !session.suppressAuthRouting else { return } // ← don’t thrash routing mid-onboarding
            if phase == .active {
                log(".active → session.refreshUser() (no unlock changes here)")
                session.refreshUser()
            }
        }
    }
}
