import SwiftUI

struct ConfirmEmailView: View {
    @State private var otpCode = ""
    @State private var showingIncomeSetup = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 24) {
                Text("Confirm Email")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Enter OTP sent to Your Email")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
            
            // OTP Input Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter OTP", text: $otpCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 44)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                validateOTP()
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
            .padding(.bottom, 50)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingIncomeSetup) {
            IncomeSetupView()
        }
        .alert("Invalid OTP", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func validateOTP() {
        if otpCode == "123" {
            showingIncomeSetup = true
        } else {
            alertMessage = "Please enter the correct OTP: 123"
            showAlert = true
        }
    }
}

#Preview {
    ConfirmEmailView()
}
