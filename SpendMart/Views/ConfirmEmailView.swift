import SwiftUI
import FirebaseAuth

struct ConfirmEmailView: View {
    var userEmail: String?
    var onVerified: (() -> Void)? = nil     // call when verified
    var onChangeEmail: (() -> Void)? = nil  // dismiss to change email

    @Environment(\.scenePhase) private var scenePhase

    @State private var isSending = false
    @State private var cooldown = 0
    @State private var message = ""
    @State private var pollTask: Task<Void, Never>? = nil   // cancel on leave
    @State private var firedOnce = false                    // avoid double-calling onVerified

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 16) {
                Text("Verify your email")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.top, 60)

                Text("We sent a verification link to\(userEmailText). Tap it to continue.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // I've clicked the link
            Button {
                Task { await checkNow(showFeedbackIfNotYet: true) }
            } label: {
                Text("I've clicked the link")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }

            // Resend
            Button {
                Task { await resend() }
            } label: {
                HStack(spacing: 8) {
                    if isSending { ProgressView() }
                    Text(cooldown > 0 ? "Resend in \(cooldown)s" : "Resend email")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(cooldown > 0 ? Color.gray.opacity(0.4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            .disabled(isSending || cooldown > 0)

            // Change email
            Button { onChangeEmail?() } label: {
                Text("Change email").foregroundColor(.gray)
            }
            .padding(.top, 4)

            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { startPolling() }
        .onDisappear { pollTask?.cancel() }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await checkNow(showFeedbackIfNotYet: false) } // re-check when user comes back
            }
        }
    }

    private var userEmailText: String {
        if let email = userEmail, !email.isEmpty { return " \(email)" }
        return ""
    }

    // MARK: - Verification checks

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled && !firedOnce {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
                await checkNow(showFeedbackIfNotYet: false)
            }
        }
    }

    private func checkNow(showFeedbackIfNotYet: Bool) async {
        guard !firedOnce, let user = Auth.auth().currentUser else { return }
        do {
            try await user.reload()
            if user.isEmailVerified {
                firedOnce = true
                await MainActor.run { onVerified?() }
            } else if showFeedbackIfNotYet {
                await MainActor.run {
                    message = "Still not verified. Please tap the link in your email, then try again."
                }
            }
        } catch {
            // ignore transient errors; keep polling
        }
    }

    // MARK: - Resend

    private func startCooldown() {
        cooldown = 30
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if cooldown > 0 { cooldown -= 1 } else { t.invalidate() }
        }
    }

    private func resend() async {
        guard let user = Auth.auth().currentUser else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await user.sendEmailVerification()
            await MainActor.run {
                message = "Verification email sent. Check your inbox (and spam)."
            }
            startCooldown()
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
}

#Preview {
    ConfirmEmailView(userEmail: "user@example.com")
}
