import SwiftUI

struct CategoriesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: ExpenseCategory?
    
    let categories: [ExpenseCategory] = [
        ExpenseCategory(name: "Food & Dining", icon: "fork.knife", color: .orange, amount: 450, budget: 800),
        ExpenseCategory(name: "Transportation", icon: "car.fill", color: .blue, amount: 320, budget: 500),
        ExpenseCategory(name: "Shopping", icon: "bag.fill", color: .purple, amount: 780, budget: 600),
        ExpenseCategory(name: "Entertainment", icon: "tv.fill", color: .red, amount: 220, budget: 400),
        ExpenseCategory(name: "Bills & Utilities", icon: "house.fill", color: .green, amount: 950, budget: 1000),
        ExpenseCategory(name: "Healthcare", icon: "heart.fill", color: .pink, amount: 150, budget: 300),
        ExpenseCategory(name: "Education", icon: "book.fill", color: .indigo, amount: 200, budget: 250),
        ExpenseCategory(name: "Travel", icon: "airplane", color: .cyan, amount: 0, budget: 500)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header Stats
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("Monthly Spending")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("LKR 3,070")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("of LKR 4,350 budget")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Overall progress
                            VStack(spacing: 8) {
                                ProgressView(value: 3070 ¬/ 4350)
                                    .tint(.blue)
                                    .scaleEffect(x: 1, y: 2)
                                
                                HStack {
                                    Text("70% of budget used")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("LKR 1,280 remaining")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Categories Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(categories) { category in
                                CategoryCard(category: category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // TODO: Add new category
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
    }
}

struct ExpenseCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let amount: Double
    let budget: Double
    
    var percentage: Double {
        min(amount / budget, 1.0)
    }
    
    var isOverBudget: Bool {
        amount > budget
    }
}

struct CategoryCard: View {
    let category: ExpenseCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(category.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(category.color)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(category.percentage * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(category.isOverBudget ? .red : category.color)
                        
                        if category.isOverBudget {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("LKR \(Int(category.amount))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("of LKR \(Int(category.budget))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: category.percentage)
                    .tint(category.isOverBudget ? .red : category.color)
                    .scaleEffect(x: 1, y: 1.2, anchor: .center)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryDetailView: View {
    let category: ExpenseCategory
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Category Details for \(category.name)")
                    .font(.title2)
                    .padding()
                
                // TODO: Add detailed category view with transactions
                
                Spacer()
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CategoriesView()
}
