import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class DueStore: ObservableObject {
    @Published var dues: [Due] = []
    private let db = Firestore.firestore()

    func listen() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid)
            .collection("dues")
            .order(by: "dueDate")
            .addSnapshotListener { [weak self] snap, err in
                if let err = err { print("⚠️ due listen:", err); return }
                let docs = snap?.documents ?? []
                self?.dues = docs.map { d in
                    let x = d.data()
                    return Due(
                        id: d.documentID,
                        itemId: x["itemId"] as? String ?? "",
                        categoryId: x["categoryId"] as? String ?? "",
                        itemTitle: x["itemTitle"] as? String ?? "Installment",
                        installmentIndex: x["installmentIndex"] as? Int ?? 1,
                        installments: x["installments"] as? Int ?? 1,
                        amount: x["amount"] as? Double ?? 0,
                        dueDate: (x["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: x["status"] as? String ?? "pending",
                        createdAt: (x["createdAt"] as? Timestamp)?.dateValue()
                    )
                }
            }
    }

    func markPaid(dueId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("dues").document(dueId)
                .updateData(["status": "paid"])
            NotificationManager.shared.cancel(id: dueId)
        } catch {
            print("⚠️ markPaid:", error)
        }
    }
}

private func lkr(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "LKR"
    f.maximumFractionDigits = (v.rounded() == v) ? 0 : 2
    return f.string(from: NSNumber(value: v)) ?? "LKR \(Int(v))"
}

struct DueListView: View {
    @StateObject private var store = DueStore()
    @State private var filter: DueFilter = .upcoming

    enum DueFilter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming", today = "Today", overdue = "Overdue", paid = "Paid"
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .upcoming: return .blue
            case .today: return .orange
            case .overdue: return .red
            case .paid: return .green
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Dues")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                    }
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DueFilter.allCases) { filterOption in
                                FilterTab(
                                    title: filterOption.rawValue,
                                    count: getFilterCount(filterOption),
                                    isSelected: filter == filterOption,
                                    color: filterOption.color
                                ) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        filter = filterOption
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Content
                if filteredDues().isEmpty {
                    EmptyStateView(filter: filter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredDues()) { due in
                                DueCard(due: due) {
                                    Task { await store.markPaid(dueId: due.id) }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthIfNeeded()
            store.listen()
        }
    }

    private func filteredDues() -> [Due] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        switch filter {
        case .upcoming:
            return store.dues.filter { $0.status == "pending" && $0.dueDate >= todayEnd }
        case .today:
            return store.dues.filter { $0.status == "pending" && $0.dueDate >= todayStart && $0.dueDate < todayEnd }
        case .overdue:
            return store.dues.filter { $0.status == "pending" && $0.dueDate < todayStart }
        case .paid:
            return store.dues.filter { $0.status == "paid" }
        }
    }
    
    private func getFilterCount(_ filter: DueFilter) -> Int {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        
        switch filter {
        case .upcoming:
            return store.dues.filter { $0.status == "pending" && $0.dueDate >= todayEnd }.count
        case .today:
            return store.dues.filter { $0.status == "pending" && $0.dueDate >= todayStart && $0.dueDate < todayEnd }.count
        case .overdue:
            return store.dues.filter { $0.status == "pending" && $0.dueDate < todayStart }.count
        case .paid:
            return store.dues.filter { $0.status == "paid" }.count
        }
    }
}


private struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color.opacity(0.3) : color.opacity(0.1))
                        )
                }
            }
            .foregroundColor(isSelected ? color : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct DueCard: View {
    let due: Due
    let onMarkPaid: () -> Void
    
    private var isOverdue: Bool {
        due.status == "pending" && due.dueDate < Calendar.current.startOfDay(for: Date())
    }
    
    private var isToday: Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        return due.status == "pending" && due.dueDate >= todayStart && due.dueDate < todayEnd
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Amount Badge
            VStack(spacing: 4) {
                Text("LKR")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f", due.amount))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            
            
            VStack(alignment: .leading, spacing: 6) {
                Text(due.itemTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Installment \(due.installmentIndex) of \(due.installments)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : isToday ? .orange : .secondary)
                    
                    Text(due.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : isToday ? .orange : .secondary)
                        .fontWeight(isOverdue || isToday ? .medium : .regular)
                    
                    if isOverdue {
                        Text("• Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    } else if isToday {
                        Text("• Due Today")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
           
            if due.status == "pending" {
                Button(action: onMarkPaid) {
                    Text("Mark Paid")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue)
                        )
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Paid")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isOverdue ? Color.red.opacity(0.3) :
                            isToday ? Color.orange.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

private struct EmptyStateView: View {
    let filter: DueListView.DueFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var emptyStateIcon: String {
        switch filter {
        case .upcoming: return "calendar.badge.clock"
        case .today: return "clock.badge.exclamationmark"
        case .overdue: return "exclamationmark.triangle"
        case .paid: return "checkmark.circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .upcoming: return "No Upcoming Dues"
        case .today: return "Nothing Due Today"
        case .overdue: return "No Overdue Payments"
        case .paid: return "No Paid Dues"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .upcoming: return "You're all caught up! No upcoming payments to worry about."
        case .today: return "Great! No payments are due today."
        case .overdue: return "Excellent! You have no overdue payments."
        case .paid: return "No payment history to show yet."
        }
    }
}
