import Foundation
import FirebaseAuth
import FirebaseFirestore

enum ExpenseService {
    static func addExpense(
        title: String,
        amount: Double,
        when date: Date,
        categoryId: String? = nil,
        categoryName: String? = nil,
        itemType: String? = nil,
        status: String? = nil,
        warrantyExp: Date? = nil,
        // ↓↓↓ NEW optional fields with defaults ↓↓↓
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        // ---------------------------------------
        source: String = "manual",
        rawText: String = ""
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let expensesRef = userRef.collection("expenses")

        var exp: [String: Any] = [
            "title": title,
            "amount": amount,
            "currency": "LKR",
            "date": Timestamp(date: date),
            "source": source,
            "rawText": rawText,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let categoryId { exp["categoryId"] = categoryId }
        if let categoryName { exp["categoryName"] = categoryName }
        if let itemType { exp["itemType"] = itemType }
        if let status { exp["status"] = status }
        if let warrantyExp { exp["warrantyExp"] = Timestamp(date: warrantyExp) }

        // New optional location fields
        if let locationName { exp["locationName"] = locationName }
        if let latitude { exp["latitude"] = latitude }
        if let longitude { exp["longitude"] = longitude }

        _ = try await expensesRef.addDocument(data: exp)

        // update dashboard progress
        try await userRef.setData([
            "financials": ["budgetSpent": FieldValue.increment(amount)]
        ], merge: true)
    }
}
