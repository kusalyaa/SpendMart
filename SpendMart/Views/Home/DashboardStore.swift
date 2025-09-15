import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Centralized data source for Home.
/// Pulls profile + financials directly from Firestore and computes derived values.
final class DashboardStore: ObservableObject {
    // Profile
    @Published var displayName: String = ""

    // Financials (raw)
    @Published var income: Double = 0
    @Published var expenses: Double = 0
    @Published var budget: Double = 0
    @Published var budgetSpent: Double = 0
    @Published var emergencyFund: Double = 0
    @Published var emergencyGoal: Double = 0
    @Published var creditLimit: Double = 0
    @Published var creditUsed: Double = 0
    @Published var net: Double = 0 // Net After Expenses (server field if present, else computed)

    // Derived
    var budgetRemaining: Double { max(budget - budgetSpent, 0) }
    var creditAvailable: Double { max(creditLimit - creditUsed, 0) }
    var emergencyLeftToGoal: Double { max(emergencyGoal - emergencyFund, 0) }

    /// Free cash = income − expenses − budget − EF (never below 0)
    var freeCash: Double { max((income - expenses) - budget - emergencyFund, 0) }

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func bind() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()

        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snap, _ in
            guard let self, let data = snap?.data() else { return }

            // Profile (support both nested and legacy)
            if let p = data["profile"] as? [String: Any] {
                self.displayName = p["name"] as? String ?? self.displayName
            } else {
                self.displayName = data["name"] as? String ?? self.displayName
            }

            // Financials
            let f = data["financials"] as? [String: Any] ?? [:]
            self.income        = f["monthlyIncome"]   as? Double ?? 0
            self.expenses      = f["monthlyExpenses"] as? Double ?? 0
            self.budget        = f["monthlyBudget"]   as? Double ?? 0
            self.budgetSpent   = f["budgetSpent"]     as? Double ?? 0
            self.emergencyFund = f["emergencyFund"]   as? Double ?? 0
            self.emergencyGoal = f["emergencyGoal"]   as? Double ?? 0

            // Credit (handle missing safely)
            let c = data["credit"] as? [String: Any] ?? [:]
            self.creditLimit = c["limit"] as? Double ?? 0
            self.creditUsed  = c["used"]  as? Double ?? 0

            // Net after expenses: prefer stored field, else compute
            if let serverNet = f["netAfterExpenses"] as? Double {
                self.net = serverNet
            } else {
                self.net = (self.income - self.expenses) - self.budgetSpent
            }
        }
    }

    deinit { listener?.remove() }
}
