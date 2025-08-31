import Foundation
import FirebaseFirestore

// MARK: - Models

struct OTPData: Codable {
    let code: String
    let expiresAt: Date
    var verified: Bool
}

struct Financials: Codable {
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var monthlyBudget: Double
}

// MARK: - Service

final class UserService {
    static let shared = UserService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }
    private var users: CollectionReference { db.collection("users") }

    // MARK: - Utils

    /// Safely coerce Firestore numeric fields (NSNumber/Double/Int/String) to Double.
    private static func toDouble(_ any: Any?) -> Double {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) ?? 0 }
        return 0
    }

    // MARK: - User Bootstrap / Profile

    /// Upsert user document on first registration
    func createOrMergeUser(uid: String, email: String, name: String?, occupation: String?) async throws {
        let ref = users.document(uid)
        let snap = try? await ref.getDocument()

        var data: [String: Any] = [
            "uid": uid,
            "email": email,
            "updatedAt": FieldValue.serverTimestamp(),
            "otpVerified": false
        ]
        if let name { data["displayName"] = name }
        if let occupation { data["occupation"] = occupation }

        if (snap?.exists == false) || snap == nil {
            data["createdAt"] = FieldValue.serverTimestamp()
        }

        try await ref.setData(data, merge: true)
    }

    // MARK: - OTP (kept)

    func generateAndStoreOTP(for uid: String, ttlMinutes: Int = 10) async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let expires = Date().addingTimeInterval(TimeInterval(ttlMinutes * 60))
        let data: [String: Any] = [
            "otp": ["code": code, "expiresAt": Timestamp(date: expires), "verified": false],
            "otpVerified": false,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await users.document(uid).setData(data, merge: true)
        return code
    }

    func isOTPVerified(uid: String) async throws -> Bool {
        let snap = try await users.document(uid).getDocument()
        guard let data = snap.data() else { return false }
        if let v = data["otpVerified"] as? Bool { return v }
        if let otp = data["otp"] as? [String: Any], let v = otp["verified"] as? Bool { return v }
        return false
    }

    func ensureUserDoc(_ user: AppUser) async throws {
        try await users.document(user.uid).setData(user.toDict(), merge: true)
    }

    func verifyOTP(uid: String, code: String) async throws -> Bool {
        let ref = users.document(uid)
        let snap = try await ref.getDocument()
        guard let data = snap.data(),
              let otp = data["otp"] as? [String: Any],
              let storedCode = otp["code"] as? String,
              let ts = otp["expiresAt"] as? Timestamp else { return false }

        let notExpired = ts.dateValue() >= Date()
        if storedCode == code && notExpired {
            try await ref.setData([
                "otp": ["code": storedCode, "expiresAt": ts, "verified": true],
                "otpVerified": true,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            return true
        }
        return false
    }

    // MARK: - Financials + Initial Balances/Credit

    /// Save income/expenses/budget and ensure starting balances & credit limit are initialized.
    func updateFinancials(uid: String, income: Double, expenses: Double, budget: Double) async throws {
        let net = max(income - expenses, 0)

        // We keep both "monthlyBudget" (canonical) and "budget" (legacy readers).
        // budgetSpent is initialized (or no-op if already present).
        let data: [String: Any] = [
            "financials": [
                "monthlyIncome": income,
                "monthlyExpenses": expenses,
                "monthlyBudget": budget,
                "budget": budget,
                "budgetSpent": FieldValue.increment(0.0),
                "netAfterExpenses": net
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let userRef = users.document(uid)
        try await userRef.setData(data, merge: true)

        // Initialize balances & credit (idempotent; also repairs limit==0)
        try await ensureInitialBalancesAndCredit(uid: uid, income: income, expenses: expenses, budget: budget)
    }

    /// Optional helper to fetch financials for prefill
    func fetchFinancials(uid: String) async throws -> Financials? {
        let snap = try await users.document(uid).getDocument()
        guard let root = snap.data(),
              let dict = root["financials"] as? [String: Any] else { return nil }

        let income  = Self.toDouble(dict["monthlyIncome"])
        let expenses = Self.toDouble(dict["monthlyExpenses"])
        let budget = dict["monthlyBudget"].map(Self.toDouble) ?? Self.toDouble(dict["budget"])
        return Financials(monthlyIncome: income, monthlyExpenses: expenses, monthlyBudget: budget)
    }

    /// Ensure starting balances & credit limit exist; safe to call multiple times (transaction).
    func ensureInitialBalancesAndCredit(uid: String, income: Double, expenses: Double, budget: Double) async throws {
        let userRef = users.document(uid)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ (tx, errPtr) -> Any? in
                do {
                    let snap = try tx.getDocument(userRef)
                    let root = snap.data() ?? [:]

                    // ---- Balances (set once / repair) ----
                    let balances = (root["balances"] as? [String: Any]) ?? [:]
                    let currentAny   = balances["currentBalance"]
                    let emergencyAny = balances["emergencyFundBalance"]
                    let goalAny      = balances["emergencyFundGoal"]          // ← NEW

                    let currentVal = Self.toDouble(currentAny)
                    if currentAny == nil || currentVal == 0 {
                        let net = max(income - expenses, 0)
                        tx.setData(["balances": ["currentBalance": net]], forDocument: userRef, merge: true)
                    }
                    if emergencyAny == nil {
                        tx.setData(["balances": ["emergencyFundBalance": 0.0]], forDocument: userRef, merge: true)
                    }
                    if goalAny == nil {                                        // ← NEW
                        tx.setData(["balances": ["emergencyFundGoal": 0.0]], forDocument: userRef, merge: true)
                    }


                    // ---- Credit: create if missing OR if limit is 0 ----
                    let credit = (root["credit"] as? [String: Any]) ?? [:]
                    let limitVal = Self.toDouble(credit["limit"])
                    if limitVal <= 0 {
                        let limit = Self.computeInitialCreditLimit(income: income, expenses: expenses, budget: budget)
                        let patch: [String: Any] = [
                            "limit": limit,
                            "used": Self.toDouble(credit["used"]),   // keep if present; else 0
                            "apr":  Self.toDouble(credit["apr"]),    // set later when plans exist
                            "score": Self.toDouble(credit["score"]), // grows later (performance/docs)
                            "updatedAt": FieldValue.serverTimestamp()
                        ]
                        tx.setData(["credit": patch], forDocument: userRef, merge: true)
                    }

                    return nil
                } catch {
                    errPtr?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            })
        }
    }

    /// Initial credit = (cushion × multiplier), capped.
    /// cushion = (income - expenses) - clampedBudget, with clampedBudget ≤ disposable
    /// multiplier = 0.8 + 0.7 * riskScore, where:
    ///   stability = 1 - (expenses/income)
    ///   prudence = 1 - (budget/disposable)
    ///   riskScore = (stability + prudence)/2
    /// caps: min 10k (if income>0), max 500k, and ≤ 60% of income. Rounded to nearest 500.
    private static func computeInitialCreditLimit(income: Double, expenses: Double, budget: Double) -> Double {
        let inc = max(income, 0)
        let exp = max(expenses, 0)

        // 1) Disposable and budget clamp
        let disposable = max(inc - exp, 0)
        let budgetClamped = min(max(budget, 0), disposable)

        // 2) Cushion after budgeting
        let cushion = max(disposable - budgetClamped, 0)

        // 3) Risk scores
        let expenseRatio = inc > 0 ? min(max(exp / inc, 0), 1) : 1
        let stability = 1 - expenseRatio
        let prudence = disposable > 0 ? 1 - (budgetClamped / disposable) : 0
        let riskScore = (stability + prudence) / 2.0

        // 4) Multiplier (0.8 .. 1.5)
        let multiplier = 0.8 + 0.7 * riskScore

        var limit = cushion * multiplier

        // 5) Caps
        let incomeCap = inc * 0.60
        let hardMax  = 500_000.0
        let hardMin  = (inc > 0) ? 10_000.0 : 0.0
        limit = min(limit, incomeCap)
        limit = min(limit, hardMax)
        limit = max(limit, hardMin)

        // Round to nearest 500
        return (limit / 500.0).rounded() * 500.0
    }

    // MARK: - (Future) credit helpers

    /// Increase credit.used (user pays with credit)
    func addCreditSpend(uid: String, amount: Double) async throws {
        guard amount > 0 else { return }
        try await users.document(uid).setData(["credit": ["used": FieldValue.increment(amount)]], merge: true)
    }

    /// Decrease credit.used (user repays)
    func addCreditRepayment(uid: String, amount: Double) async throws {
        guard amount > 0 else { return }
        try await users.document(uid).setData(["credit": ["used": FieldValue.increment(-amount)]], merge: true)
    }
}
