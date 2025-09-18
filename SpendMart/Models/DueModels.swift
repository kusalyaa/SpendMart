import Foundation

struct Due: Identifiable {
    var id: String
    var itemId: String
    var categoryId: String
    var itemTitle: String
    var installmentIndex: Int
    var installments: Int
    var amount: Double
    var dueDate: Date
    var status: String              
    var createdAt: Date?
}
