import Foundation

struct Category: Identifiable, Codable {
    var id: String?
    var name: String
    var colorHex: String
    var createdAt: Date?
}

struct Item: Identifiable, Codable {
    var id: String?

    
    var title: String
    var description: String?
    var amount: Double
    var note: String?
    var date: Date
    var createdAt: Date?

    
    var categoryId: String?
    var categoryName: String?

    
    var paymentMethod: String?      // "Wallet" | "Credit" | "Wallet+Credit"
    var status: String?             // Wallet: "Paid"|"Pay"; Credit: "Pay"|"To be paid"
    var installments: Int?          // 3 | 6 | 12
    var interestMonthlyRate: Double?
    var interestTotal: Double?
    var totalPayable: Double?
    var perInstallment: Double?

    
    var walletPaid: Double?
    var creditPrincipal: Double?
    var creditInstallments: Int?
    var creditInterestRate: Double?
    var creditInterestTotal: Double?
    var creditTotalPayable: Double?
    var creditPerInstallment: Double?

    
    var locationName: String?
    var latitude: Double?
    var longitude: Double?

    
    var warrantyExp: Date?

    
    var imageURL: String?
}
