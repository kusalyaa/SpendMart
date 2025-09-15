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
            .order(by: "dueDate") // server timestamp or date field
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

struct DueListView: View {
    @StateObject private var store = DueStore()
    @State private var filter: Filter = .upcoming

    enum Filter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming", today = "Today", overdue = "Overdue", paid = "Paid"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            ForEach(filteredDues()) { due in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground))
                        Text(String(format: "LKR\n%.0f", due.amount))
                            .font(.caption).bold()
                            .multilineTextAlignment(.center)
                            .padding(6)
                    }
                    .frame(width: 64, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(due.itemTitle)
                            .font(.body)
                        Text("Installment \(due.installmentIndex) of \(due.installments)")
                            .font(.caption).foregroundColor(.secondary)
                        Text(due.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    if due.status == "pending" {
                        Button("Mark Paid") {
                            Task { await store.markPaid(dueId: due.id) }
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dues")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
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
}
