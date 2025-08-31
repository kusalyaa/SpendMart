import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class DashboardStore: ObservableObject {
    @Published var displayName: String = ""

    // Financials
    @Published var income: Double = 0
    @Published var expenses: Double = 0
    @Published var budget: Double = 0
    @Published var budgetSpent: Double = 0
    @Published var net: Double = 0

    var budgetRemaining: Double { max(budget - budgetSpent, 0) }

    // Balances
    @Published var currentBalance: Double = 0
    @Published var emergencyFund: Double = 0
    @Published var emergencyGoal: Double = 0   // ← NEW
    var emergencyLeftToGoal: Double { max(emergencyGoal - emergencyFund, 0) }

    // Credit
    @Published var creditLimit: Double = 0
    @Published var creditUsed: Double = 0
    var creditAvailable: Double { max(creditLimit - creditUsed, 0) }

    private var sub: ListenerRegistration?
    private var triedCreditRepair = false

    func bind() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("users").document(uid)
        sub?.remove()
        sub = ref.addSnapshotListener { [weak self] snap, _ in
            guard let self = self, let data = snap?.data() else { return }

            self.displayName = (data["displayName"] as? String) ?? ""

            if let fin = data["financials"] as? [String: Any] {
                self.income        = Self.toDouble(fin["monthlyIncome"])
                self.expenses      = Self.toDouble(fin["monthlyExpenses"])
                self.budget        = fin["monthlyBudget"].map(Self.toDouble) ?? Self.toDouble(fin["budget"])
                self.budgetSpent   = Self.toDouble(fin["budgetSpent"])
                self.net           = fin["netAfterExpenses"].map(Self.toDouble) ?? max(self.income - self.expenses, 0)
            } else {
                self.income = 0; self.expenses = 0; self.budget = 0; self.budgetSpent = 0; self.net = 0
            }

            if let bal = data["balances"] as? [String: Any] {
                self.currentBalance = Self.toDouble(bal["currentBalance"])
                self.emergencyFund  = Self.toDouble(bal["emergencyFundBalance"])
                self.emergencyGoal  = Self.toDouble(bal["emergencyFundGoal"])   // ← NEW (defaults to 0)
            } else {
                self.currentBalance = 0; self.emergencyFund = 0; self.emergencyGoal = 0
            }

            if let credit = data["credit"] as? [String: Any] {
                self.creditLimit = Self.toDouble(credit["limit"])
                self.creditUsed  = Self.toDouble(credit["used"])
            } else {
                self.creditLimit = 0; self.creditUsed = 0
            }

            // one-time repair if needed
            if !self.triedCreditRepair, self.creditLimit <= 0, self.income > 0 {
                self.triedCreditRepair = true
                Task {
                    try? await UserService.shared.ensureInitialBalancesAndCredit(
                        uid: uid, income: self.income, expenses: self.expenses, budget: self.budget
                    )
                }
            }
        }
    }

    deinit { sub?.remove() }

    private static func toDouble(_ any: Any?) -> Double {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) ?? 0 }
        return 0
    }
}
