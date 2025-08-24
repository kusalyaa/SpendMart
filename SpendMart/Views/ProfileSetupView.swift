import SwiftUI
import FirebaseAuth

private enum ProfileRoute: Hashable {
    case income
}

struct ProfileSetupView: View {
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
                                .textInputAutocapitalization(.none)   // ✅ don’t capitalize
                                .autocorrectionDisabled(true)        // ✅ don’t autocorrect
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
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSuccessToast)
    }

    // MARK: - Logic
    private func validateAndContinue() {
        guard !postLogin else {
            alertMessage = "You are already logged in."
            showAlert = true
            return
        }
        if name.isEmpty { alertMessage = "Please enter your name"; showAlert = true; return }
        if selectedOccupation.isEmpty { alertMessage = "Please select your occupation"; showAlert = true; return }
        if !isValidEmail(email) { alertMessage = "Please enter a valid email address"; showAlert = true; return }
        if password.count < 6 { alertMessage = "Password must be at least 6 characters"; showAlert = true; return }

        isSaving = true

        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let uid = result.user.uid
                await MainActor.run {
                    isSaving = false
                    successMessage = "Account created (Auth). Finishing setup…"
                    showSuccessToast = true
                    path.append(.income)
                }

                Task.detached {
                    do {
                        try await UserService.shared.createOrMergeUser(
                            uid: uid,
                            email: email,
                            name: name,
                            occupation: selectedOccupation
                        )
                    } catch {
                        print("Profile save failed: \(error)")
                    }
                }

                // Save profile in Firestore (blocking, optional fallback)
                try await UserService.shared.createOrMergeUser(
                    uid: uid,
                    email: email,
                    name: name,
                    occupation: selectedOccupation
                )

                await MainActor.run {
                    isSaving = false
                    successMessage = "Account created successfully."
                    showSuccessToast = true
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
