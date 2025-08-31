import Foundation

enum ReceiptParser {
    static func parse(text: String) -> ScannedExpense {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let amount = detectTotal(lines: lines)
        let date = detectDate(text: text)
        let merchant = detectMerchant(lines: lines)
        return ScannedExpense(merchant: merchant, amount: amount, date: date, rawText: text)
    }

    private static func detectMerchant(lines: [String]) -> String {
        let ban = ["RECEIPT","INVOICE","BILL","TAX","VAT","TOTAL","AMOUNT","SUBTOTAL","DATE",
                   "TIME","CASHIER","CARD","CHANGE"]
        for l in lines.prefix(6) {
            let u = l.uppercased()
            if !ban.contains(where: { u.contains($0) }) &&
               u.range(of: #"^[-–—_/\\#\d\.: ]+$"#, options: .regularExpression) == nil {
                return l
            }
        }
        return "Receipt"
    }

    private static func detectDate(text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
        return matches.first?.date
    }

    private static func detectTotal(lines: [String]) -> Double {
        let keys = ["GRAND TOTAL","TOTAL","AMOUNT DUE","BALANCE DUE","TOTAL DUE","NET TOTAL"]
        let regex = try! NSRegularExpression(
            pattern: #"(?i)(?:LKR|Rs\.?|රු)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#
        )
        var cands: [(score: Int, value: Double)] = []

        for line in lines {
            let r = NSRange(location: 0, length: line.utf16.count)
            let matches = regex.matches(in: line, options: [], range: r)
            guard !matches.isEmpty else { continue }
            let hasKey = keys.contains(where: { line.uppercased().contains($0) })
            for m in matches {
                if let rr = Range(m.range(at: 1), in: line) {
                    let v = Double(line[rr].replacingOccurrences(of: ",", with: "")) ?? 0
                    cands.append((hasKey ? 2 : 1, v))
                }
            }
        }

        if let best = cands.sorted(by: { ($0.score, $0.value) > ($1.score, $1.value) }).first {
            return best.value
        }

        // fallback: largest number anywhere
        let joined = lines.joined(separator: " ")
        let ms = regex.matches(in: joined, options: [], range: NSRange(joined.startIndex..., in: joined))
        return ms.compactMap {
            if let rr = Range($0.range(at: 1), in: joined) {
                return Double(joined[rr].replacingOccurrences(of: ",", with: ""))
            }
            return nil
        }.max() ?? 0
    }
}
