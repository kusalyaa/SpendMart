import SwiftUI

// MARK: - Helpers

private func lkr(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "LKR"
    f.maximumFractionDigits = (v.rounded() == v) ? 0 : 2
    return f.string(from: NSNumber(value: v)) ?? "LKR \(Int(v))"
}

// MARK: - Home

struct HomeView: View {
    @StateObject private var store = DashboardStore()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Greeting (keep title in nav bar to avoid duplicate text)
                    if !store.displayName.isEmpty {
                        Text("Good morning, \(store.displayName)")
                            .font(.headline)
                            .foregroundColor(.appSecondaryTxt)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    // ===== BLUE BALANCE CARD =====
                    BalanceCard(
                        total: store.net,             // Net After Expenses
                        income: store.income,
                        expense: store.expenses,
                        freeCash: store.freeCash
                    )
                    .padding(.horizontal, 16)

                    // ===== TIGHT, PERFECTLY ALIGNED 2-CELL CARD =====
                    StatsRowCard(
                        leftTitle: "Emergency Fund",
                        leftValue: store.emergencyFund,
                        // ⚠️ Per your request: keep the SAME value you had before,
                        // only rename the label to "Budget Spent".
                        rightTitle: "Budget Spent",
                        rightValue: store.budgetRemaining
                    )
                    .padding(.horizontal, 16)

                    // ===== COMPACT GAUGES (Budget & Credit) =====
                    InsightCard {
                        HStack(spacing: 12) {
                            MiniGauge(
                                title: "Budget",
                                current: store.budgetSpent,
                                total: max(store.budget, 1),
                                tint: Color.appBrand
                            )
                            MiniGauge(
                                title: "Credit",
                                current: store.creditUsed,
                                total: max(store.creditLimit, 1),
                                tint: Color.orange
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // ===== QUICK ACTIONS =====
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        QuickActionsRow()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { store.bind() }
        .tint(Color.appBrand)
    }
}

// MARK: - Cards & Components

/// Blue card with a small Free Cash badge.
fileprivate struct BalanceCard: View {
    var total: Double
    var income: Double
    var expense: Double
    var freeCash: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.appBrand, Color.appBrand.opacity(0.85)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 10) {
                Text("Total Balance")
                    .foregroundColor(.white.opacity(0.9))
                Text(lkr(total))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income").foregroundColor(.white.opacity(0.9))
                        Text(lkr(income)).foregroundColor(.white).fontWeight(.semibold)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expense").foregroundColor(.white.opacity(0.9))
                        Text(lkr(expense)).foregroundColor(.white).fontWeight(.semibold)
                    }
                }
                .padding(.top, 8)

                // Free Cash badge
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "wallet.pass")
                            .imageScale(.small)
                        Text("Free Cash: \(lkr(max(freeCash, 0)))")
                            .font(.footnote).bold()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .frame(height: 160)
        .shadow(color: Color.appBrand.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

/// One shared card with two equal cells + a subtle divider, so alignment is perfect.
fileprivate struct StatsRowCard: View {
    var leftTitle: String
    var leftValue: Double
    var rightTitle: String
    var rightValue: Double

    var body: some View {
        HStack(spacing: 0) {
            StatCell(title: leftTitle, value: leftValue)
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 1)
            StatCell(title: rightTitle, value: rightValue)
        }
        .frame(height: 96) // common fixed height for perfect alignment
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
}

fileprivate struct StatCell: View {
    var title: String
    var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryTxt)
            Text(lkr(value))
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(.clear) // both halves share the outer card
    }
}

fileprivate struct InsightCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Mini circular gauges

fileprivate struct MiniGauge: View {
    var title: String
    var current: Double
    var total: Double
    var tint: Color

    private var pct: Double {
        guard total > 0 else { return 0 }
        return min(max(current / total, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Gauge(value: current, in: 0...max(total, 1)) { }
                    .gaugeStyle(.accessoryCircular)
                    .tint(tint)
                    .frame(width: 72, height: 72)

                VStack(spacing: 0) {
                    Text("\(Int(pct * 100))%")
                        .font(.subheadline).bold()
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.appSecondaryTxt)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Text("\(lkr(current)) / \(lkr(total))")
                .font(.caption2)
                .foregroundColor(.appSecondaryTxt)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Quick Actions

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
                    .font(.title2).foregroundColor(color)
            }
            .frame(width: 72, height: 72)
            Text(title).fontWeight(.semibold)
            Text(subtitle).font(.footnote).foregroundColor(.appSecondaryTxt)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
}
