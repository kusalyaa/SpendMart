import SwiftUI

private func lkr(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "LKR"
    f.maximumFractionDigits = (v.rounded() == v) ? 0 : 2
    return f.string(from: NSNumber(value: v)) ?? "LKR \(Int(v))"
}

struct HomeView: View {
    @StateObject private var store = DashboardStore()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Title + greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold))
                        if !store.displayName.isEmpty {
                            Text("Good morning,")
                                .foregroundStyle(.secondary)
                            Text(store.displayName)
                                .font(.title3).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    
                    BalanceCard(
                        total: store.net,
                        income: store.income,
                        expense: store.expenses,
                        freeCash: store.freeCash
                    )
                    .padding(.horizontal, 16)

                    
                    HStack(spacing: 12) {
                        InfoCard(title: "Emergency Fund", amount: store.emergencyFund)
                        InfoCard(title: "Budget Spent", amount: store.budgetSpent)
                    }
                    .padding(.horizontal, 16)

                    
                    VStack(spacing: 12) {
                        ProgressRow(
                            title: "Monthly Budget",
                            current: store.budgetRemaining,
                            total: max(store.budget, 1),
                            trailingText: "\(lkr(store.budgetRemaining)) / \(lkr(store.budget))",
                            progress: store.budget > 0 ? (store.budget - store.budgetRemaining) / store.budget : 0
                        )

                        ProgressRow(
                            title: "Credit Limit",
                            current: store.creditAvailable,
                            total: max(store.creditLimit, 1),
                            trailingText: "\(lkr(store.creditAvailable)) / \(lkr(store.creditLimit))",
                            progress: store.creditLimit > 0 ? store.creditAvailable / store.creditLimit : 0
                        )
                    }
                    .padding(.horizontal, 16)

                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    QuickActionsRow()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear { store.bind() }
    }
}


fileprivate struct BalanceCard: View {
    var total: Double
    var income: Double
    var expense: Double
    var freeCash: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 12) {
                Text("Total Balance")
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.subheadline)
                
                Text(lkr(total))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.caption)
                        Text(lkr(income))
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expense")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.caption)
                        Text(lkr(expense))
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                }
                
               
                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.caption)
                    Text("Free Cash: \(lkr(freeCash))")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(height: 160)
    }
}

fileprivate struct InfoCard: View {
    var title: String
    var amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(lkr(amount))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

fileprivate struct ProgressRow: View {
    var title: String
    var current: Double
    var total: Double
    var trailingText: String?
    var progress: Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
                Text(trailingText ?? "\(lkr(current)) / \(lkr(total))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            
            ProgressView(value: min(max(progress, 0), 1))
                .tint(.blue)
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

fileprivate struct QuickActionsRow: View {
    var body: some View {
        HStack(spacing: 14) {
            ActionTile(title: "Scan", subtitle: "QR & Barcode", color: .purple, system: "qrcode.viewfinder")
            ActionTile(title: "Categories", subtitle: "Manage", color: .green, system: "square.grid.2x2.fill")
            ActionTile(title: "Due", subtitle: "Payments", color: .orange, system: "calendar.badge.exclamationmark")
        }
    }
}

fileprivate struct ActionTile: View {
    var title: String
    var subtitle: String
    var color: Color
    var system: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12))
                Image(systemName: system)
                    .font(.title2).foregroundStyle(color)
            }
            .frame(width: 70, height: 70)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
