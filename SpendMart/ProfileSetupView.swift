import SwiftUI

struct ProfileSetupView: View {
    @State private var name = ""
    @State private var selectedOccupation = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showingLogin = false
    @State private var showOccupationPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // TODO: Fetch occupations from database/API
    // This should be populated from a database or API call
    private let occupations = [
        "Software Engineer", "Doctor", "Teacher", "Lawyer", "Accountant",
        "Marketing Manager", "Sales Representative", "Nurse", "Architect",
        "Graphic Designer", "Data Analyst", "Project Manager", "Consultant",
        "Engineer", "Business Analyst", "HR Manager", "Finance Manager",
        "Student", "Entrepreneur", "Other"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 24) {
                Text("Profile Setup")
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
                    Text("Name")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Occupation")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showOccupationPicker = true
                    }) {
                        HStack {
                            Text(selectedOccupation.isEmpty ? "Select Occupation" : selectedOccupation)
                                .foregroundColor(selectedOccupation.isEmpty ? .gray : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                        .frame(height: 44)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
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
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue Button and Login Link
            VStack(spacing: 16) {
                Button(action: {
                    validateAndContinue()
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
                    showingLogin = true
                }) {
                    Text("Already have account? Log In")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingLogin) {
            LoginView()
        }
        .actionSheet(isPresented: $showOccupationPicker) {
            ActionSheet(
                title: Text("Select Occupation"),
                buttons: occupations.map { occupation in
                    ActionSheet.Button.default(Text(occupation)) {
                        selectedOccupation = occupation
                    }
                } + [ActionSheet.Button.cancel()]
            )
        }
        .alert("Validation Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
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
        
        if email.isEmpty || !isValidEmail(email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        if password.count < 6 {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        // TODO: Save user data to database
        // Save profile data: name, selectedOccupation, email, password
        // API call: POST /api/users/register
        /*
         let userData = [
             "name": name,
             "occupation": selectedOccupation,
             "email": email,
             "password": password
         ]
         */
        
        showingLogin = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    ProfileSetupView()
}
