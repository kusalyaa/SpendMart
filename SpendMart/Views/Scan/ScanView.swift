import SwiftUI
import Vision
import VisionKit
import UIKit

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var navigateToAddItem = false
    @State private var coordinator: ScannerCoordinator?
    @State private var hasPresented = false

    @State private var extractedTitle: String?
    @State private var extractedDescription: String?
    @State private var extractedAmount: String?
    @State private var extractedDate: Date?

    var body: some View {
        NavigationStack {
            Text("Scanning…")
                .onAppear {
                    guard !hasPresented else { return }
                    hasPresented = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentScanner()
                    }
                }
                .navigationDestination(isPresented: $navigateToAddItem) {
                    AddItemView(
                        preselectedCategoryId: nil,
                        preselectedCategoryName: nil,
                        preselectedCategoryColorHex: nil,
                        presetTitle: extractedTitle,
                        presetDescription: extractedDescription,
                        presetAmount: extractedAmount,
                        presetDate: extractedDate
                    )
                }
        }
    }

    private func presentScanner() {
        let c = ScannerCoordinator(onFinish: handleScannedImage)
        self.coordinator = c

        #if targetEnvironment(simulator)
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = c
        UIApplication.presentOnRoot(picker)
        #else
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = c
        UIApplication.presentOnRoot(scanner)
        #endif
    }

    private func handleScannedImage(_ image: UIImage?) {
        defer {
            self.coordinator = nil
            self.hasPresented = false
        }
        guard let img = image else {
            dismiss()
            return
        }
        recognizeText(from: img)
    }

    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            dismiss()
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                DispatchQueue.main.async { self.navigateToAddItem = true }
                return
            }

            let recognizedStrings = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .map { Self.cleanedLine($0) }

            self.parseAndRoute(from: recognizedStrings)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func parseAndRoute(from linesIn: [String]) {
        let lines = linesIn
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let (title, titleIdx) = guessVendorTitleWithIndex(from: lines)
        let foundDate = detectDate(in: lines)

        let amountCands = collectAmountCandidates(in: lines)
        let amountBest = strictTotalAmount(from: amountCands, lines: lines) ??
                         bestAmountFallback(from: amountCands)

        let desc = buildStoreMetaSnippet(from: lines, titleIndex: titleIdx, date: foundDate)

        DispatchQueue.main.async {
            self.extractedTitle = title
            self.extractedDescription = desc
            self.extractedAmount = amountBest?.normalizedString
            self.extractedDate = foundDate
            self.navigateToAddItem = true
        }
    }

    private static func cleanedLine(_ s: String) -> String {
        var t = s.replacingOccurrences(of: #"[*•]{2,}"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"-{2,}"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"_{2,}"#, with: "", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func detectDate(in lines: [String]) -> Date? {
        let fmts = ["dd/MM/yyyy","MM/dd/yyyy","yyyy-MM-dd","dd-MM-yyyy","dd.MM.yyyy","dd.MM.yy","d/M/yy","d-M-yy","dd/MM/yy"]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        for line in lines.prefix(12) {
            for f in fmts {
                df.dateFormat = f
                if let d = df.date(from: line) { return d }
            }
        }
        let full = lines.joined(separator: " ")
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(full.startIndex..<full.endIndex, in: full)
        return detector.matches(in: full, options: [], range: range).first?.date
    }

    private struct AmountCandidate {
        let value: Decimal
        let normalizedString: String
        let lineIndex: Int
        let raw: String
    }

    private func collectAmountCandidates(in lines: [String]) -> [AmountCandidate] {
        let pattern = #"""
        (?ix)
        (?:^|[\s:])
        (?:USD|CHF|LKR|Rs\.?|₨|\$|€|£)?\s*
        (
          \d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})
          | \d+(?:[.,]\d{2})
          | \d{1,3}(?:[.,]\d{3})+
          | \d+
        )
        \s*(?:USD|CHF|LKR|Rs\.?|₨|\$|€|£)?
        """#

        var out: [AmountCandidate] = []
        for (i, line) in lines.enumerated() {
            let ns = line as NSString
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            regex.enumerateMatches(in: line, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
                guard let match = match, match.numberOfRanges >= 2 else { return }
                let raw = ns.substring(with: match.range(at: 1))
                if let normalized = normalizeAmountString(raw),
                   let dec = Decimal(string: normalized) {
                    out.append(AmountCandidate(value: dec, normalizedString: normalized, lineIndex: i, raw: raw))
                }
            }
        }
        return out
    }

    private func normalizeAmountString(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespaces)

        let lastDot = s.lastIndex(of: ".")
        let lastComma = s.lastIndex(of: ",")
        var decimalSep: Character? = nil
        if let d = lastDot, let c = lastComma { decimalSep = (d > c) ? "." : "," }
        else if lastDot != nil { decimalSep = "." }
        else if lastComma != nil { decimalSep = "," }

        if let sep = decimalSep {
            let other: Character = (sep == ".") ? "," : "."
            s.removeAll(where: { $0 == other })
            if sep == "," { s = s.replacingOccurrences(of: ",", with: ".") }
        }

        if s.contains(".") == false { s.append(".00") }
        else {
            let comps = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            if comps.count == 2 {
                var frac = String(comps[1])
                if frac.count == 1 { frac.append("0") }
                else if frac.count > 2 { frac = String(frac.prefix(2)) }
                s = comps[0] + "." + frac
            }
        }
        return s
    }

    private func strictTotalAmount(from cands: [AmountCandidate], lines: [String]) -> AmountCandidate? {
        guard !cands.isEmpty else { return nil }
        let totalWords = ["TOTAL AMOUNT", "GRAND TOTAL", "AMOUNT DUE", "BALANCE DUE", "TOTAL:" , "TOTAL"].map { $0.uppercased() }
        let excludeWords = ["CASH", "CHANGE", "TENDERED", "PAID", "CARD", "BANK CARD", "TIP",
                            "APPROVAL", "RECEIPT", "INVOICE", "RECHNR", "NO.", "NR"]

        func amounts(inLine idx: Int) -> [AmountCandidate] {
            let allowed = excludeWords.allSatisfy { !lines[idx].uppercased().contains($0) }
            if !allowed { return [] }
            return cands.filter { $0.lineIndex == idx }.sorted { $0.value > $1.value }
        }

        for (i, s) in lines.enumerated() {
            let up = s.uppercased()
            guard totalWords.contains(where: { up.contains($0) }) else { continue }

            if let pick = amounts(inLine: i).first { return pick }

            for nxt in (i+1)...min(i+5, lines.count-1) {
                let upNext = lines[nxt].uppercased()
                if excludeWords.contains(where: { upNext.contains($0) }) { continue }
                if let pick = amounts(inLine: nxt).first { return pick }
            }
        }
        return nil
    }

    private func bestAmountFallback(from cands: [AmountCandidate]) -> AmountCandidate? {
        return cands.sorted(by: { $0.value > $1.value }).first
    }

    private func guessVendorTitleWithIndex(from lines: [String]) -> (String?, Int?) {
        let ignore = ["RECEIPT","INVOICE","TERMINAL","APPROVAL","BANK CARD","CARD","CASH","CHANGE","TOTAL","AMOUNT","SUBTOTAL","TAX","VAT","MWST","MWST.","INCL.","BALANCE","THANK YOU","TABLE","TISCH","BARCODE"]
        let amountRegex = try! NSRegularExpression(pattern: #"(USD|CHF|LKR|Rs\.?|₨|\$|€|£)|\d"#, options: .caseInsensitive)

        for (idx, line) in lines.prefix(10).enumerated() {
            let up = line.uppercased()
            if ignore.contains(where: { up.contains($0) }) { continue }
            if amountRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) != nil { continue }
            if line.count >= 3, line.rangeOfCharacter(from: .letters) != nil {
                return (line, idx)
            }
        }
        if let idx = lines.firstIndex(where: { !$0.isEmpty && $0.rangeOfCharacter(from: .letters) != nil }) {
            return (lines[idx], idx)
        }
        return ("Receipt", nil)
    }

    private func buildStoreMetaSnippet(from lines: [String], titleIndex: Int?, date: Date?) -> String? {
        guard let tIdx = titleIndex else { return nil }

        let metaKeys = ["TERMINAL", "TERMINAL#", "RECEIPT", "RECHNR", "TABLE", "TISCH", "APPROVAL", "CASHIER", "REGISTER", "LANE"]
        var pieces: [String] = []

        for i in (tIdx+1)..<min(lines.count, tIdx+6) {
            let ln = lines[i]
            let up = ln.uppercased()
            if metaKeys.contains(where: { up.contains($0) }) {
                pieces.append(String(ln.prefix(40)))
                if pieces.count == 2 { break }
            }
        }

        if pieces.isEmpty, tIdx + 1 < lines.count {
            let candidate = lines[tIdx + 1]
            let hasAmount = candidate.range(of: #"(USD|CHF|LKR|Rs\.?|₨|\$|€|£)|\d+[.,]\d{2}\b"#, options: .regularExpression) != nil
            if !hasAmount && candidate.count <= 40 {
                pieces.append(candidate)
            }
        }

        if let d = date {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateStyle = .short
            df.timeStyle = .short
            pieces.append(df.string(from: d))
        }

        guard !pieces.isEmpty else { return nil }
        return String(pieces.joined(separator: " · ").prefix(60))
    }
}

// MARK: - Coordinator
final class ScannerCoordinator: NSObject,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    VNDocumentCameraViewControllerDelegate {

    let onFinish: (UIImage?) -> Void

    init(onFinish: @escaping (UIImage?) -> Void) {
        self.onFinish = onFinish
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var img: UIImage?
        if let edited = info[.editedImage] as? UIImage { img = edited }
        else if let original = info[.originalImage] as? UIImage { img = original }
        picker.dismiss(animated: true) { self.onFinish(img) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { self.onFinish(nil) }
    }

    #if !targetEnvironment(simulator)
    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFinishWith scan: VNDocumentCameraScan) {
        let img = (scan.pageCount > 0) ? scan.imageOfPage(at: 0) : nil
        controller.dismiss(animated: true) { self.onFinish(img) }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { self.onFinish(nil) }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFailWithError error: Error) {
        controller.dismiss(animated: true) { self.onFinish(nil) }
    }
    #endif
}

// MARK: - Present helper
extension UIApplication {
    static func presentOnRoot(_ vc: UIViewController) {
        let rootVC: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController

        guard var top = rootVC else { return }
        while let presented = top.presentedViewController { top = presented }
        top.present(vc, animated: true)
    }
}
