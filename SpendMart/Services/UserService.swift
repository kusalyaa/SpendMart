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

    /// Safely coerce Firestore numeric fields (NSNumber/Double/Int) to Double.
    private func toDouble(_ any: Any?) -> Double {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
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
            // make sure this exists with a known default
            "otpVerified": false
        ]
        if let name { data["displayName"] = name }
        if let occupation { data["occupation"] = occupation }

        // If this is a brand new doc, also set createdAt
        if (snap?.exists == false) || snap == nil {
            data["createdAt"] = FieldValue.serverTimestamp()
        }

        try await ref.setData(data, merge: true)
    }

    // MARK: - OTP (kept as-is, small robustness only)

    /// Generate a 6-digit OTP, store with expiry (default 10 minutes), and mark as not verified
    func generateAndStoreOTP(for uid: String, ttlMinutes: Int = 10) async throws -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let expires = Date().addingTimeInterval(TimeInterval(ttlMinutes * 60))
        let data: [String: Any] = [
            "otp": [
                "code": code,
                "expiresAt": Timestamp(date: expires),
                "verified": false
            ],
            "otpVerified": false,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await users.document(uid).setData(data, merge: true)
        return code
    }

    /// Check whether OTP has been verified already
    func isOTPVerified(uid: String) async throws -> Bool {
        let snap = try await users.document(uid).getDocument()
        guard let data = snap.data() else { return false }
        if let verified = data["otpVerified"] as? Bool { return verified }
        if let otp = data["otp"] as? [String: Any], let v = otp["verified"] as? Bool { return v }
        return false
    }

    /// Back-compat for older call sites (e.g., SessionViewModel)
    func ensureUserDoc(_ user: AppUser) async throws {
        try await users.document(user.uid).setData(user.toDict(), merge: true)
    }

    /// Validate OTP and set verified=true if correct + not expired
    func verifyOTP(uid: String, code: String) async throws -> Bool {
        let ref = users.document(uid)
        let snap = try await ref.getDocument()
        guard let data = snap.data(),
              let otp = data["otp"] as? [String: Any],
              let storedCode = otp["code"] as? String,
              let ts = otp["expiresAt"] as? Timestamp
        else {
            return false
        }

        let notExpired = ts.dateValue() >= Date()
        let matches = (storedCode == code)
        if matches && notExpired {
            try await ref.setData([
                "otp": [
                    "code": storedCode,
                    "expiresAt": ts,
                    "verified": true
                ],
                "otpVerified": true,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            return true
        }
        return false
    }

    // MARK: - Financials + Initial Balances/Credit

    /// Save income/expenses/budget under users/{uid}/financials (merge; safe to call many times).
    /// Also initializes balances + initial credit limit (one-time) using a transaction.
    func updateFinancials(uid: String, income: Double, expenses: Double, budget: Double) async throws {
        let net = max(income - expenses, 0)

        // Write financials (keep BOTH keys: "monthlyBudget" and "budget" for compatibility)
        let data: [String: Any] = [
            "financials": [
                "monthlyIncome": income,
                "monthlyExpenses": expenses,
                "monthlyBudget": budget,   // canonical
                "budget": budget,          // compatibility with older readers
                "netAfterExpenses": net
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
        let userRef = users.document(uid)
        try await userRef.setData(data, merge: true)

        // Initialize balances & credit (idempotent)
        try await ensureInitialBalancesAndCredit(uid: uid, income: income, expenses: expenses, budget: budget)
    }

    /// Optional helper to fetch financials for prefill
    func fetchFinancials(uid: String) async throws -> Financials? {
        let snap = try await users.document(uid).getDocument()
        guard let root = snap.data(),
              let dict = root["financials"] as? [String: Any] else { return nil }

        let income = toDouble(dict["monthlyIncome"])
        let expenses = toDouble(dict["monthlyExpenses"])
        // read both keys; prefer canonical "monthlyBudget"
        let budget = dict["monthlyBudget"].map(toDouble) ?? toDouble(dict["budget"])

        return Financials(monthlyIncome: income, monthlyExpenses: expenses, monthlyBudget: budget)
    }

    func ensureInitialBalancesAndCredit(uid: String, income: Double, expenses: Double, budget: Double) async throws {
        let userRef = users.document(uid)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ (tx, errPtr) -> Any? in
                do {
                    let snap = try tx.getDocument(userRef)
                    let root = snap.data() ?? [:]

                    // ---- Balances (set once; or repair if zero) ----
                    let balances = (root["balances"] as? [String: Any]) ?? [:]
                    let currentAny = balances["currentBalance"]
                    let emergencyAny = balances["emergencyFundBalance"]

                    let currentVal = self.toDouble(currentAny)
                    let emergencyVal = self.toDouble(emergencyAny)

                    if currentAny == nil || currentVal == 0 {
                        let net = max(income - expenses, 0)
                        tx.setData(["balances": ["currentBalance": net]], forDocument: userRef, merge: true)
                    }
                    if emergencyAny == nil {
                        tx.setData(["balances": ["emergencyFundBalance": 0.0]], forDocument: userRef, merge: true)
                    }

                    // ---- Credit (create if missing OR if limit is 0) ----
                    let credit = (root["credit"] as? [String: Any]) ?? [:]
                    let limitVal = self.toDouble(credit["limit"])
                    if limitVal <= 0 {
                        let limit = Self.computeInitialCreditLimit(income: income, expenses: expenses, budget: budget)
                        let patch: [String: Any] = [
                            "limit": limit,
                            "used": self.toDouble(credit["used"]),
                            "apr": self.toDouble(credit["apr"]),      // set later when plans exist
                            "score": self.toDouble(credit["score"]),  // grows later from performance/docs
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


    /// Initial credit = 80% of disposable (net - budget), capped to LKR 10k–500k.
    private static func computeInitialCreditLimit(income: Double, expenses: Double, budget: Double) -> Double {
        let net = max(income - expenses, 0)
        let clampedBudget = max(min(budget, net), 0)
        let disposable = max(net - clampedBudget, 0)
        let base = disposable * 0.80
        // Caps (adjust anytime): min 10,000 ; max 500,000 LKR
        let capped = min(max(base, 10_000), 500_000)
        return capped
    }

    // MARK: - (Future) credit helpers — stubs to avoid later refactors

    /// Increase credit.used (e.g., user pays with credit). Call with a positive amount.
    func addCreditSpend(uid: String, amount: Double) async throws {
        guard amount > 0 else { return }
        let ref = users.document(uid)
        try await ref.setData([
            "credit": ["used": FieldValue.increment(amount)]
        ], merge: true)
    }

    /// Decrease credit.used (e.g., user repays). Call with a positive amount.
    func addCreditRepayment(uid: String, amount: Double) async throws {
        guard amount > 0 else { return }
        let ref = users.document(uid)
        try await ref.setData([
            "credit": ["used": FieldValue.increment(-amount)]
        ], merge: true)
    }
}
