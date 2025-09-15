import Foundation

struct Due: Identifiable {
    var id: String
    var itemId: String
    var categoryId: String
    var itemTitle: String
    var installmentIndex: Int        // 1..N
    var installments: Int           // total N
    var amount: Double
    var dueDate: Date
    var status: String              // "pending" | "paid"
    var createdAt: Date?
}
