
import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
               
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hi John!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Welcome back")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .padding(.horizontal)
                
                
                VStack(spacing: 16) {
                    Text("Total Balance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("LKR 45,230")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Income")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("LKR 50,000")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        VStack {
                            Text("Expenses")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("LKR 4,770")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Quick Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        NavigationLink(destination: ScanView()) {
                            QuickActionButton(
                                icon: "camera.fill",
                                title: "Scan",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: CategoriesView()) {
                            QuickActionButton(
                                icon: "square.grid.2x2",
                                title: "Categories",
                                color: .green
                            )
                        }
                        
                        NavigationLink(destination: DueView()) {
                            QuickActionButton(
                                icon: "doc.text.fill",
                                title: "Due",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
