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

    // MARK: - OTP

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

    // MARK: - Financials (Income / Expenses / Budget)

    /// Saves income, expenses, and budget under users/{uid}.financials (merged).
    /// Example doc shape:
    /// users/{uid} {
    ///   financials: {
    ///     monthlyIncome: 100000,
    ///     monthlyExpenses: 45000,
    ///     monthlyBudget: 25000
    ///   },
    ///   updatedAt: <server time>
    /// }
    func updateFinancials(uid: String, income: Double, expenses: Double, budget: Double) async throws {
        let ref = users.document(uid)
        let data: [String: Any] = [
            "financials": [
                "monthlyIncome": income,
                "monthlyExpenses": expenses,
                "monthlyBudget": budget
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await ref.setData(data, merge: true)
    }

    /// Optional helper to fetch financials for prefill
    func fetchFinancials(uid: String) async throws -> Financials? {
        let snap = try await users.document(uid).getDocument()
        guard let root = snap.data(),
              let dict = root["financials"] as? [String: Any] else { return nil }

        let income = dict["monthlyIncome"] as? Double ?? 0
        let expenses = dict["monthlyExpenses"] as? Double ?? 0
        let budget = dict["monthlyBudget"] as? Double ?? 0
        return Financials(monthlyIncome: income, monthlyExpenses: expenses, monthlyBudget: budget)
    }
}
