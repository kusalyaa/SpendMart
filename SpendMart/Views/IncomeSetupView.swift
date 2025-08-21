import SwiftUI

struct IncomeSetupView: View {
    @State private var monthlyIncome = ""
    @State private var useAutoBudget = true
    @State private var showingDashboard = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 24) {
                    Text("Income Setup")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.top, 60)
                    
                    // Dollar Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                        
                        Text("$")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 40)
                
                // Monthly Income Field
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Monthly Income", text: $monthlyIncome)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                        .keyboardType(.numberPad)
                    
                    // Auto Budget Toggle
                    HStack {
                        Text("Use auto-budget (80% of income)")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $useAutoBudget)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    handleContinue()
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
            .fullScreenCover(isPresented: $showingDashboard) {
                RootTabView()
            }
            .alert("Invalid Income", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid monthly income amount.")
            }
        }
    }
    
    private func handleContinue() {
        // Validate the income input
        guard let income = Double(monthlyIncome), income > 0 else {
            showAlert = true
            return
        }
        
        // Process the data
        print("Income setup completed")
        print("Monthly Income: \(monthlyIncome)")
        print("Use Auto Budget: \(useAutoBudget)")
        
        // Navigate to Dashboard
        showingDashboard = true
    }
}

#Preview {
    IncomeSetupView()
}
