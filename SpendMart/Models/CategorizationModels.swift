import Foundation

struct Category: Identifiable, Codable {
    var id: String?
    var name: String
    var colorHex: String
    var createdAt: Date?
}

struct Item: Identifiable, Codable {
    var id: String?

    // basics
    var title: String
    var description: String?
    var amount: Double
    var note: String?
    var date: Date
    var createdAt: Date?

    // categorization
    var categoryId: String?
    var categoryName: String?

    // payment / status
    var paymentMethod: String?      // "Wallet" | "Credit" | "Wallet+Credit"
    var status: String?             // Wallet: "Paid"|"Pay"; Credit: "Pay"|"To be paid"
    var installments: Int?          // 3 | 6 | 12
    var interestMonthlyRate: Double?
    var interestTotal: Double?
    var totalPayable: Double?
    var perInstallment: Double?

    // split when wallet insufficient
    var walletPaid: Double?
    var creditPrincipal: Double?
    var creditInstallments: Int?
    var creditInterestRate: Double?
    var creditInterestTotal: Double?
    var creditTotalPayable: Double?
    var creditPerInstallment: Double?

    // location
    var locationName: String?
    var latitude: Double?
    var longitude: Double?

    // warranty
    var warrantyExp: Date?

    // media
    var imageURL: String?
}
