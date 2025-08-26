import SwiftUI

struct BiometricGateView: View {
    var onUnlocked: () -> Void
    @State private var isPrompting = false
    @State private var lastFailed = false

    private var title: String {
        switch BiometricAuth.available() {
        case .faceID:  return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        case .none:    return "Unlock"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(.blue)
                .padding(.bottom, 8)

            Text("SpendSmart is Locked")
                .font(.title3).fontWeight(.semibold)

            if lastFailed {
                Text("Authentication failed. Try again.")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            Button {
                prompt()
            } label: {
                HStack {
                    if isPrompting { ProgressView().tint(.white) }
                    Text(isPrompting ? "Authenticating..." : title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            }
            .disabled(isPrompting)

            Spacer()
            Text("Face ID/Passcode protects your financial data.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .onAppear { prompt() }                 // auto-prompt on open
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // auto-prompt when returning to foreground if still locked
            if !isPrompting { prompt() }
        }
    }

    private func prompt() {
        isPrompting = true
        lastFailed = false
        BiometricAuth.authenticate { success in
            isPrompting = false
            if success {
                onUnlocked()
            } else {
                lastFailed = true
            }
        }
    }
}
