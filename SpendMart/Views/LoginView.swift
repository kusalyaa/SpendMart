import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingCreateAccount = false

    // Routing
    @State private var presentVerify = false
    @State private var showDashboard = false   // -> DashboardView()

    // Feedback
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 24) {
                Text("Log In")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.top, 60)

                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 40)

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email").font(.system(size: 14)).foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password").font(.system(size: 14)).foregroundColor(.gray)
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                Button(action: { handleLogin() }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Button(action: { showingCreateAccount = true }) {
                    HStack(spacing: 4) {
                        Text("No account?").foregroundColor(.gray)
                        Text("Create Account").foregroundColor(.blue)
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color.white)
        .navigationBarHidden(true)

        // Create account (sign up)
        .fullScreenCover(isPresented: $showingCreateAccount) { ProfileSetupView() }

        // "Check your email" screen
        .fullScreenCover(isPresented: $presentVerify) {
            ConfirmEmailView(
                userEmail: email,
                onVerified: { verifiedNavigationFromVerify() },
                onChangeEmail: { presentVerify = false } // dismiss to edit email
            )
        }

        // Dashboard after verified
        .fullScreenCover(isPresented: $showDashboard) {
            RootTabView()   
        }

        // Errors
        .alert("Login Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(alertMessage) }

        // Loader
        .overlay(
            Group {
                if isLoading {
                    ProgressView("Signing in…")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 6)
                }
            }
        )
    }

    // Dismiss the verify cover, then present dashboard
    private func verifiedNavigationFromVerify() {
        Task {
            guard let user = Auth.auth().currentUser else { return }
            do {
                try await user.reload()
                if user.isEmailVerified {
                    await MainActor.run { presentVerify = false }
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
                    await MainActor.run { showDashboard = true }
                }
            } catch {
                // ignore transient errors; verify screen stays
            }
        }
    }

    // MARK: - Logic
    private func handleLogin() {
        // reset routing defensively
        presentVerify = false
        showDashboard = false

        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address"
            showAlert = true; return
        }
        guard !password.isEmpty else {
            alertMessage = "Please enter your password"
            showAlert = true; return
        }

        isLoading = true
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let user = result.user

                // Always reload to get fresh verification status
                try await user.reload()
                let verified = Auth.auth().currentUser?.isEmailVerified ?? user.isEmailVerified

                if verified {
                    isLoading = false
                    showDashboard = true
                } else {
                    // Send verification email (idempotent)
                    try await user.sendEmailVerification()
                    isLoading = false
                    presentVerify = true
                }
            } catch {
                isLoading = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

#Preview { LoginView() }
