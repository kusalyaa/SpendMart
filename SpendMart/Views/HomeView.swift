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
                VStack(alignment: .leading, spacing: 16) {

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

                    // BLUE CARD
                    BalanceCard(
                        total: store.net,             // "Total Balance" = Net After Expenses
                        income: store.income,
                        expense: store.expenses
                    )
                    .padding(.horizontal, 16)

                    // PROGRESS ROWS
                    ProgressRow(
                        title: "Monthly Budget",
                        current: store.budgetRemaining,
                        total: max(store.budget, 1),
                        trailingText: "\(lkr(store.budgetRemaining)) / \(lkr(store.budget))"
                    )
                    .padding(.horizontal, 16)

                    ProgressRow(
                        title: "Emergency Fund",
                        current: store.emergencyFund,
                        total: max(store.emergencyGoal, 0), // goal can be 0 initially
                        trailingText: store.emergencyGoal > 0
                            ? "\(lkr(store.emergencyFund)) / \(lkr(store.emergencyGoal)) • \(lkr(store.emergencyLeftToGoal)) to go"
                            : "\(lkr(0)) / \(lkr(0))"
                    )

                    .padding(.horizontal, 16)

                    ProgressRow(
                        title: "Credit Limit",
                        current: store.creditAvailable,
                        total: max(store.creditLimit, 1),
                        trailingText: "\(lkr(store.creditAvailable)) / \(lkr(store.creditLimit))"
                    )
                    .padding(.horizontal, 16)

                    // QUICK ACTIONS
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

// MARK: - Components

fileprivate struct BalanceCard: View {
    var total: Double
    var income: Double
    var expense: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 10) {
                Text("Total Balance")
                    .foregroundStyle(.white.opacity(0.9))
                Text(lkr(total))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income").foregroundStyle(.white.opacity(0.9))
                        Text(lkr(income)).foregroundStyle(.white).fontWeight(.semibold)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expense").foregroundStyle(.white.opacity(0.9))
                        Text(lkr(expense)).foregroundStyle(.white).fontWeight(.semibold)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .frame(height: 140)
    }
}

fileprivate struct ProgressRow: View {
    var title: String
    var current: Double
    var total: Double
    var trailingText: String?

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(current / total, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text(trailingText ?? "\(lkr(current)) / \(lkr(total))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(.blue)
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
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
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12))
                Image(systemName: system)
                    .font(.title2).foregroundStyle(color)
            }
            .frame(width: 72, height: 72)
            Text(title).fontWeight(.semibold)
            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
