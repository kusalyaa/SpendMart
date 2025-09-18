import SwiftUI
import FirebaseAuth

private enum ProfileRoute: Hashable { case income }

struct ProfileSetupView: View {
    @EnvironmentObject var session: AppSession   // ⬅️ add this

    // Default registration flow uses postLogin = false
    let postLogin: Bool
    init(postLogin: Bool = false) { self.postLogin = postLogin }

    // Navigation
    @State private var path: [ProfileRoute] = []

    // Form
    @State private var name = ""
    @State private var selectedOccupation = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showOccupationPicker = false

    // Other navigation
    @State private var showingLogin = false

    // Feedback
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessToast = false
    @State private var successMessage = ""

    private let occupations = [
        "Software Engineer","Doctor","Teacher","Lawyer","Accountant",
        "Nurse","Designer","Developer","Engineer","Marketing Manager",
        "Sales Executive","Product Manager","Data Scientist","HR Manager",
        "Business Analyst","Architect","Pharmacist","Dentist","Chef","Writer"
    ]

    private func log(_ msg: String, file: StaticString = #fileID, line: Int = #line) {
        print("[Flow][Profile] \(msg)  (\(file):\(line))")
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
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

                    // Form
                    VStack(spacing: 20) {
                        fieldBlock(title: "Name") {
                            TextField("Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                        }

                        fieldBlock(title: "Occupation") {
                            Button { showOccupationPicker = true } label: {
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
                                .autocorrectionDisabled(true)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                                .disabled(postLogin)
                                .opacity(postLogin ? 0.6 : 1)
                        }

                        fieldBlock(title: "Password") {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(height: 44)
                                .disabled(postLogin)
                                .opacity(postLogin ? 0.6 : 1)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Continue + Login
                    VStack(spacing: 16) {
                        Button {
                            log("Continue tapped")
                            validateAndContinue()
                        } label: {
                            Text(isSaving ? "Creating…" : "Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 24)

                        Button { showingLogin = true } label: {
                            HStack(spacing: 4) {
                                Text("Already have account?").foregroundColor(.gray)
                                Text("Log In").foregroundColor(.blue)
                            }
                            .font(.system(size: 14))
                        }
                    }
                    .padding(.bottom, 50)
                }
                .navigationTitle("")
                .navigationBarHidden(true)

                // Toast
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
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Loader
                if isSaving {
                    ProgressView("Saving…")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 6)
                }
            }
            // Occupation picker
            .actionSheet(isPresented: $showOccupationPicker) {
                ActionSheet(
                    title: Text("Select Occupation"),
                    buttons: occupations.map { occ in
                        ActionSheet.Button.default(Text(occ)) { selectedOccupation = occ }
                    } + [ActionSheet.Button.cancel()]
                )
            }
            // Alerts
            .alert("Validation Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
            // Login
            .fullScreenCover(isPresented: $showingLogin) { LoginView() }
            // Destination
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .income:
                    IncomeSetupView()
                        .environmentObject(session)
                        .onAppear { log("➡️ Arrived at IncomeSetupView") }
                }
            }
            .onAppear {
                session.suppressAuthRouting = true     // ⬅️ freeze root routing during onboarding
                log("ProfileSetupView appeared | suppressAuthRouting=true")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSuccessToast)
    }

    // MARK: - Logic
    private func validateAndContinue() {
        if postLogin {
            alertMessage = "You are already logged in."
            showAlert = true
            log("Validation failed: postLogin==true")
            return
        }
        guard !name.isEmpty else { alertMessage = "Please enter your name"; showAlert = true; log("Validation failed: name empty"); return }
        guard !selectedOccupation.isEmpty else { alertMessage = "Please select your occupation"; showAlert = true; log("Validation failed: occupation empty"); return }
        guard isValidEmail(email) else { alertMessage = "Please enter a valid email address"; showAlert = true; log("Validation failed: invalid email"); return }
        guard password.count >= 6 else { alertMessage = "Password must be at least 6 characters"; showAlert = true; log("Validation failed: weak password"); return }

        isSaving = true
        log("Starting account creation…")

        Task {
            do {
                // 1) Create auth user
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let uid = result.user.uid
                log("Auth user created uid=\(uid)")

                // 2) Save profile in Firestore (do it ONCE)
                try await UserService.shared.createOrMergeUser(
                    uid: uid,
                    email: email,
                    name: name,
                    occupation: selectedOccupation
                )
                log("Firestore profile saved for uid=\(uid)")

                // 3) Navigate ONCE to Income
                await MainActor.run {
                    isSaving = false
                    successMessage = "Account created successfully."
                    showSuccessToast = true
                    log("Navigation → .income")
                    path.append(.income)
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    if let err = error as NSError?, let code = AuthErrorCode(rawValue: err.code) {
                        switch code.code {
                        case .emailAlreadyInUse:
                            alertMessage = "An account already exists for this email. Please log in instead."
                        case .invalidEmail:
                            alertMessage = "The email address is invalid."
                        case .weakPassword:
                            alertMessage = "The password is too weak."
                        default:
                            alertMessage = err.localizedDescription
                        }
                    } else {
                        alertMessage = error.localizedDescription
                    }
                    showAlert = true
                    log("Error during creation: \(alertMessage)")
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

// MARK: - Small UI helper
@ViewBuilder
private func fieldBlock<T: View>(title: String, @ViewBuilder content: () -> T) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 14))
            .foregroundColor(.gray)
        content()
    }
}
