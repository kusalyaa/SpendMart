import SwiftUI

// MARK: - Onboarding

struct SpendSmartOnboardingView: View {
    @State private var showingProfileSetup = false
    @EnvironmentObject var session: AppSession

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    Text("$")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(spacing: 8) {
                    Text("SpendSmart")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("Track spending, save smarter.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: { showingProfileSetup = true }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .fullScreenCover(isPresented: $showingProfileSetup) {
            ProfileSetupView()   // your existing view
        }
    }
}

// MARK: - Entry View (used by AppRootView when logged out)

struct ContentView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false

    var body: some View {
        Group {
            // Only gate with biometrics if the user is ALREADY logged in
            if session.isLoggedIn && requiresBiometricGate && !unlocked {
                BiometricGateView {
                    unlocked = true
                }
            } else {
                // Normal onboarding/login content (no biometrics while logged out)
                SpendSmartOnboardingView()
            }
        }
        .onChange(of: scenePhase) { phase in
            // Re-lock whenever app goes to background
            if phase == .background { unlocked = false }
        }
    }

    private var requiresBiometricGate: Bool {
        switch BiometricAuth.available() {
        case .faceID, .touchID: return true
        case .none:             return false
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppSession())
}
