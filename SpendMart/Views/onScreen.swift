import SwiftUI

struct SpendSmartOnboardingView: View {
    @State private var showingProfileSetup = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Icon
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    
                    Text("$")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // App Title and Subtitle
                VStack(spacing: 8) {
                    Text("SpendSMart")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("Track spending, save smarter.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            
            Spacer()
            
            // Get Started Button
            Button(action: {
                showingProfileSetup = true
            }) {
                Text("Get Started")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .fullScreenCover(isPresented: $showingProfileSetup) {
            ProfileSetupView()
        }
    }
}


struct ContentView: View {
    var body: some View {
        SpendSmartOnboardingView()
    }
}

#Preview {
    ContentView()
}
