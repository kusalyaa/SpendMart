import SwiftUI

struct AddExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var amount = ""
    @State private var selectedCategory = "Food & Dining"
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var paymentMethod = "Cash"
    @State private var showingAlert = false
    
    let categories = ["Food & Dining", "Transportation", "Shopping", "Entertainment", "Bills & Utilities", "Healthcare", "Education", "Travel"]
    let paymentMethods = ["Cash", "Credit Card", "Debit Card", "Bank Transfer", "Digital Wallet"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 16) {
                            Text("Enter Amount")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("LKR")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0.00", text: $amount)
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        
                        
                        VStack(spacing: 16) {
                            Text("Category")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        CategoryChip(
                                            title: category,
                                            isSelected: category == selectedCategory
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.horizontal, -20)
                        }
                        
                        
                        VStack(spacing: 16) {
                            Text("Description")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Enter description (optional)", text: $description)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        
                        VStack(spacing: 16) {
                            Text("Date")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        
                        VStack(spacing: 16) {
                            Text("Payment Method")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Menu {
                                ForEach(paymentMethods, id: \.self) { method in
                                    Button(method) {
                                        paymentMethod = method
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(paymentMethod)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        
                        
                        Button(action: addExpense) {
                            Text("Add Expense")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Invalid Amount", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid expense amount.")
        }
    }
    
    private func addExpense() {
        guard let expenseAmount = Double(amount), expenseAmount > 0 else {
            showingAlert = true
            return
        }
        
        // TODO: Save expense to database
        print("Adding expense:")
        print("Amount: LKR \(expenseAmount)")
        print("Category: \(selectedCategory)")
        print("Description: \(description)")
        print("Date: \(selectedDate)")
        print("Payment Method: \(paymentMethod)")
       
        presentationMode.wrappedValue.dismiss()
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddExpenseView()
}
