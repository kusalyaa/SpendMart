import SwiftUI

struct SpendSmartOnboardingView: View {
    @State private var showingProfileSetup = false

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

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false

    var body: some View {
        Group {
            if unlocked {
                SpendSmartOnboardingView()
            } else {
                BiometricGateView {
                    unlocked = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Re-lock whenever app goes to background
            if newPhase == .background { unlocked = false }
        }
    }
}

#Preview { ContentView() }
