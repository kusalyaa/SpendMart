// HomeView.swift
import SwiftUI

// MARK: - Dummy values for now
// TODO: Replace with backend API values
private let monthlyBudget = (used: 400, total: 1500)
private let emergencyFund = (used: 400, total: 1500)
private let creditLimit   = (used: 400, total: 1500)

struct HomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header section
                        VStack(spacing: 16) {
                            Text("Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Welcome message
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Good morning,")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("John Abraham")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // MARK: - Balance overview card
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total Balance")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    // TODO: Replace with API total balance
                                    Text("Rs. 2,50,000")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                
                                // Card icon
                                Image(systemName: "creditcard.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack(spacing: 30) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Income")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    // TODO: Replace with API income
                                    Text("Rs. 3,00,000")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Expense")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    // TODO: Replace with API expense
                                    Text("Rs. 50,000")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // MARK: - Budget Stats Section
                        VStack(spacing: 16) {
                            BudgetStatCard(
                                title: "Monthly Budget",
                                used: monthlyBudget.used,
                                total: monthlyBudget.total,
                                color: .green
                            )
                            BudgetStatCard(
                                title: "Emergency Fund",
                                used: emergencyFund.used,
                                total: emergencyFund.total,
                                color: .red
                            )
                            BudgetStatCard(
                                title: "Credit Limit",
                                used: creditLimit.used,
                                total: creditLimit.total,
                                color: .blue
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Quick Actions Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            HStack(spacing: 20) {
                                NavigationLink(destination: ScanView()) {
                                    QuickActionCard(
                                        icon: "qrcode.viewfinder",
                                        title: "Scan",
                                        subtitle: "QR & Barcode",
                                        color: .purple
                                    )
                                }
                                
                                NavigationLink(destination: CategoriesView()) {
                                    QuickActionCard(
                                        icon: "square.grid.2x2",
                                        title: "Categories",
                                        subtitle: "Manage",
                                        color: .green
                                    )
                                }
                                
                                NavigationLink(destination: DueView()) {
                                    QuickActionCard(
                                        icon: "calendar.badge.exclamationmark",
                                        title: "Due",
                                        subtitle: "Payments",
                                        color: .orange
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Recent Transactions
                        VStack(spacing: 16) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                // TODO: Replace with dynamic list from API
                                TransactionRow(
                                    icon: "cart.fill",
                                    title: "Grocery Shopping",
                                    subtitle: "Food & Dining",
                                    amount: "-Rs. 2,500",
                                    isExpense: true
                                )
                                
                                TransactionRow(
                                    icon: "fuelpump.fill",
                                    title: "Fuel",
                                    subtitle: "Transportation",
                                    amount: "-Rs. 3,000",
                                    isExpense: true
                                )
                                
                                TransactionRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Salary",
                                    subtitle: "Income",
                                    amount: "+Rs. 75,000",
                                    isExpense: false
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
    }
}

// MARK: - Budget Card
struct BudgetStatCard: View {
    let title: String
    let used: Int
    let total: Int
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(used) / Double(total), 0), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Spacer()
                Text("LKR \(used) / \(total)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: progress)
                .tint(color)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let isExpense: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isExpense ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isExpense ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(amount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isExpense ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}
