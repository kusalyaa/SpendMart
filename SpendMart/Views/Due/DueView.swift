
import SwiftUI

struct DueView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    Text("Search")
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Unpaid")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    DueItemCard(
                        title: "Apple Watch 5",
                        date: "25th AUG 2025",
                        amount: "LKR 13,000"
                    )
                    
                    DueItemCard(
                        title: "Redmi Note 14",
                        date: "25th AUG 2025",
                        amount: "LKR 13,000"
                    )
                }
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Warranty Exp")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    DueItemCard(
                        title: "Apple Watch 5",
                        date: "25th AUG 2025",
                        amount: "LKR 13,000"
                    )
                    
                    DueItemCard(
                        title: "Redmi Note 14",
                        date: "25th AUG 2025",
                        amount: "LKR 13,000"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Due")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
