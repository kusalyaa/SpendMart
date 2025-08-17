import SwiftUI

struct HomeView: View {
    // MARK: - State (replace with data from DB / ViewModel later)
    @State private var currentBalance: Double = 299
    @State private var monthlyBudgetUsed: Double = 400
    @State private var monthlyBudgetTotal: Double = 1500
    @State private var emergencyFundUsed: Double = 400
    @State private var emergencyFundTotal: Double = 1500
    @State private var creditUsed: Double = 400
    @State private var creditTotal: Double = 1500
    @State private var showingAddExpense = false
    @State private var showingScan = false
    @State private var transactions: [Transaction] = [] // Empty means we show the placeholder

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        headerView

                        // Current Balance Card
                        balanceCard

                        // Budget Overview Cards
                        budgetCardsView

                        // Quick Actions
                        quickActionsView

                        // Recent Transactions
                        recentTransactionsView
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        }
        // .navigationBarHidden(true) // Avoid deprecated API
        .fullScreenCover(isPresented: $showingAddExpense) {
            AddExpenseSheet()
        }
        .fullScreenCover(isPresented: $showingScan) {
            // ScanView()
            // Placeholder fullScreenCover body to avoid build error if ScanView is not implemented yet
            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.largeTitle)
                Text("Scan coming soon")
                    .font(.headline)
                Button("Close") { showingScan = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("August 2025")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                // TODO: Navigate to profile
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                }
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 10)
    }

    private var balanceCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Current Balance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)

                Text("LKR \(Int(currentBalance))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Balance trend indicator
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)

                Text("+12% from last month")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private var budgetCardsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                BudgetCard(
                    title: "Monthly Budget",
                    used: monthlyBudgetUsed,
                    total: monthlyBudgetTotal,
                    color: .green,
                    icon: "creditcard.fill"
                )

                BudgetCard(
                    title: "Emergency Fund",
                    used: emergencyFundUsed,
                    total: emergencyFundTotal,
                    color: .orange,
                    icon: "shield.fill"
                )

                BudgetCard(
                    title: "Credit Limit",
                    used: creditUsed,
                    total: creditTotal,
                    color: .red,
                    icon: "arrow.trend.up"
                )

                BudgetCard(
                    title: "Savings Goal",
                    used: 800,
                    total: 2000,
                    color: .blue,
                    icon: "target"
                )
            }
        }
    }

    private var quickActionsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Expense",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: {
                        showingAddExpense = true
                    }
                )

                QuickActionButton(
                    title: "Scan Receipt",
                    icon: "camera.fill",
                    color: .green,
                    action: {
                        showingScan = true
                    }
                )

                QuickActionButton(
                    title: "Transfer",
                    icon: "arrow.left.arrow.right",
                    color: .purple,
                    action: {
                        // TODO: Navigate to transfer
                    }
                )
            }
        }
    }

    private var recentTransactionsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Button("View All") {
                    // TODO: Navigate to all transactions
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            }

            VStack(spacing: 12) {
                if transactions.isEmpty {
                    // Placeholder when there are no transactions
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            Text("No transactions yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)

                            Text("Your recent transactions will appear here")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Button("Add Your First Transaction") {
                            showingAddExpense = true
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                } else {
                    ForEach(transactions) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
        }
    }
}

// MARK: - Models & Subviews

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let date: Date
    let icon: String
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .medium))
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("LKR \(Int(transaction.amount)))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(transaction.amount < 0 ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}

struct BudgetCard: View {
    let title: String
    let used: Double
    let total: Double
    let color: Color
    let icon: String

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(used / total, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(Int(used))/\(Int(total))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    Capsule()
                        .fill(color.opacity(0.9))
                        .frame(width: max(8, geo.size.width * progress), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(Int(progress * 100))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
        }
    }
}

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Add Expense")
                    .font(.title2).bold()
                Text("This is a placeholder. Replace with your real form.")
                    .foregroundColor(.secondary)
                Button("Close") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
}
