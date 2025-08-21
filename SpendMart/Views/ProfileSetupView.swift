import SwiftUI

struct ProfileSetupView: View {
    @State private var name = ""
    @State private var selectedOccupation = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showingLogin = false
    @State private var showOccupationPicker = false

    // Validation + messages
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Success toast (auto-dismiss then go to Login)
    @State private var showSuccessToast = false
    @State private var successMessage = ""

    // TODO: Fetch occupations from database/API
    private let occupations = [
        "Software Engineer", "Doctor", "Teacher", "Lawyer", "Accountant",
        "Nurse", "Designer", "Developer", "Engineer", "Marketing Manager",
        "Sales Executive", "Product Manager", "Data Scientist", "HR Manager",
        "Business Analyst", "Architect", "Pharmacist", "Dentist", "Chef", "Writer"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header (colors aligned with LoginView)
                    VStack(spacing: 24) {
                        Text("Profile Setup")
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
                    .padding(.bottom, 32)

                    // Form fields (same style as LoginView)
                    VStack(spacing: 20) {
                        fieldBlock(title: "Name") {
                            TextField("Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                        }

                        fieldBlock(title: "Occupation") {
                            Button {
                                showOccupationPicker = true
                            } label: {
                                HStack {
                                    Text(selectedOccupation.isEmpty ? "Occupation" : selectedOccupation)
                                        .foregroundColor(selectedOccupation.isEmpty ? Color.gray.opacity(0.7) : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                )
                            }
                        }

                        fieldBlock(title: "Email") {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.none)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                        }

                        fieldBlock(title: "Password") {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Continue + Already have account? (blue link)
                    VStack(spacing: 16) {
                        Button {
                            validateAndContinue()
                        } label: {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        Button {
                            showingLogin = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have account?")
                                    .foregroundColor(.gray)
                                Text("Log In")
                                    .foregroundColor(.blue)  // ensure blue link
                            }
                            .font(.system(size: 14))
                        }
                    }
                    .padding(.bottom, 50)
                }
                .navigationBarHidden(true)

                // Success toast overlay (shows ~1.8s before navigating)
                if showSuccessToast {
                    VStack {
                        Spacer()
                        Text(successMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(12)
                            .padding(.bottom, 80)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: showSuccessToast)
                }
            }
            // Occupation picker
            .actionSheet(isPresented: $showOccupationPicker) {
                ActionSheet(
                    title: Text("Select Occupation"),
                    buttons: occupations.map { occupation in
                        .default(Text(occupation)) { selectedOccupation = occupation }
                    } + [.cancel()]
                )
            }
            // Validation alert
            .alert("Validation Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            // Login screen
            .fullScreenCover(isPresented: $showingLogin) {
                LoginView()
            }
        }
    }

    // MARK: - Behaviors

    private func validateAndContinue() {
        if name.isEmpty {
            alertMessage = "Please enter your name"
            showAlert = true
            return
        }
        if selectedOccupation.isEmpty {
            alertMessage = "Please select your occupation"
            showAlert = true
            return
        }
        if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        if password.count < 6 {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }

        // Create Firebase user and send verification
        Task {
            do {
                let user = try await AuthService.shared
                    .signUp(email: email, password: password, displayName: name)

                // Toast long enough to see, then navigate to Login
                successMessage = "Verification email sent to \(user.email ?? "your email"). Check your inbox."
                withAnimation { showSuccessToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { showSuccessToast = false }
                    showingLogin = true
                }
            } catch {
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

// MARK: - Small UI helpers to match your look

@ViewBuilder
private func fieldBlock<T: View>(title: String, @ViewBuilder content: () -> T) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 14))
            .foregroundColor(.gray)
        content()
    }
}
