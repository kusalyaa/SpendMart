import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingConfirmEmail = false
    @State private var showingCreateAccount = false
    
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
                    showingConfirmEmail = true
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
    }
}

#Preview {
    LoginView()
}
