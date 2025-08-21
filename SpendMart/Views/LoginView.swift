import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingConfirmEmail = false
    @State private var showingCreateAccount = false

    // Added: validation + error feedback (UI unchanged)
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

                // Profile Icon
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

            // Form Fields
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    // Keeping TextField as-is to preserve your UI
                    TextField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue Button and Create Account Link
            VStack(spacing: 16) {
                Button(action: {
                    handleLogin()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Button(action: {
                    showingCreateAccount = true
                }) {
                    HStack(spacing: 4) {
                        Text("No account?")
                            .foregroundColor(.gray)
                        Text("Create Account")
                            .foregroundColor(.blue)
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingConfirmEmail) {
            ConfirmEmailView()
        }
        .fullScreenCover(isPresented: $showingCreateAccount) {
            ProfileSetupView()
        }
        // Simple error alert (UI style unchanged)
        .alert("Login Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // Optional: overlay spinner text (non-intrusive, no UI layout change)
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

    // MARK: - Logic (UI unchanged)

    private func handleLogin() {
        // Basic validation (keeps your UI unchanged)
        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        guard !password.isEmpty else {
            alertMessage = "Please enter your password"
            showAlert = true
            return
        }

        isLoading = true
        Task {
            do {
                _ = try await AuthService.shared.signIn(email: email, password: password)
                // Signed in; now check email verification
                let user = Auth.auth().currentUser
                let verified = user?.isEmailVerified ?? false

                isLoading = false
                if !verified {
                    // push to ConfirmEmailView (as your UI already does)
                    showingConfirmEmail = true
                } else {
                    // Verified → Let your higher-level router (RootView/MainTabView) handle navigation
                    // Nothing else to do here to keep UI unchanged.
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

#Preview {
    LoginView()
}
