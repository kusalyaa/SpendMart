import SwiftUI
import Vision
import VisionKit
import UIKit

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss

    // Navigation
    @State private var navigateToAddItem = false

    // Keep a STRONG reference to the coordinator so delegate callbacks fire
    @State private var coordinator: ScannerCoordinator?
    @State private var hasPresented = false   // present only once per appear

    // Extracted values from Vision OCR to feed AddItemView
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
        print("🎛 Presenting photo picker (simulator)")
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = c
        UIApplication.presentOnRoot(picker)
        #else
        print("📄 Presenting VisionKit document scanner (device)")
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = c
        UIApplication.presentOnRoot(scanner)
        #endif
    }

    private func handleScannedImage(_ image: UIImage?) {
        print("📸 handleScannedImage called, image? \(image != nil)")
        guard let img = image else {
            // User canceled or no image -> go back
            dismiss()
            return
        }
        print("🖼️ picked image size: \(img.size)")
        recognizeText(from: img)
    }

    // MARK: - Vision OCR
    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { print("⚠️ No CGImage"); return }

        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error { print("❌ OCR error:", error.localizedDescription) }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("⚠️ No OCR results"); return
            }
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            print("✅ OCR Results:", recognizedStrings)

            // --- Improved parsing ---
            var foundAmount: String?
            var foundDate: Date?
            var foundTitle: String?
            var snippetLines: [String] = []

            for raw in recognizedStrings {
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                snippetLines.append(text)

                // Amount: handle Rs/LKR, commas, dot/decimal
                // Examples: "Rs 1,250.00", "LKR 1250", "1,250", "1250.50"
                if foundAmount == nil,
                   let m = text.range(of: #"(?:Rs\.?\s*|LKR\s*)?([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)"#,
                                       options: .regularExpression) {
                    var amt = String(text[m])
                    if let num = amt.range(of: #"[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?"#,
                                          options: .regularExpression) {
                        amt = String(amt[num])
                    }
                    // normalize: remove thousands commas, keep dot decimal
                    amt = amt.replacingOccurrences(of: ",", with: "")
                    foundAmount = amt
                }

                // Date: try multiple formats
                if foundDate == nil, let d = tryParseDate(from: text) {
                    foundDate = d
                }

                // Title: take the first meaningful line
                if foundTitle == nil {
                    foundTitle = text
                }
            }

            let descSnippet = snippetLines.prefix(3).joined(separator: " · ")

            DispatchQueue.main.async {
                self.extractedTitle        = foundTitle ?? "Scanned Item"
                self.extractedDescription  = descSnippet.isEmpty ? nil : descSnippet
                self.extractedAmount       = foundAmount ?? ""     // AddItemView ignores empty
                self.extractedDate         = foundDate ?? Date()
                print("➡️ Navigating to AddItemView with title:", self.extractedTitle ?? "nil")
                self.navigateToAddItem = true
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // Optionally hint language(s) if your receipts are English/Sinhala/Tamil
        // request.recognitionLanguages = ["en", "si", "ta"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("❌ Vision perform error:", error.localizedDescription)
        }
    }

    private func tryParseDate(from text: String) -> Date? {
        // Extend as needed
        let formats = ["dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "dd.MM.yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for f in formats {
            formatter.dateFormat = f
            if let d = formatter.date(from: text) { return d }
        }
        return nil
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

    // Photo Library (simulator)
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("📥 Picker didFinish, info keys:", info.keys.map { $0.rawValue })
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { self.onFinish(image) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("🚫 Picker canceled")
        picker.dismiss(animated: true) { self.onFinish(nil) }
    }

    // VisionKit (device)
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("📄 VisionKit didFinish, pages:", scan.pageCount)
        if scan.pageCount > 0 {
            let image = scan.imageOfPage(at: 0)
            controller.dismiss(animated: true) { self.onFinish(image) }
        } else {
            controller.dismiss(animated: true) { self.onFinish(nil) }
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        print("🚫 VisionKit canceled")
        controller.dismiss(animated: true) { self.onFinish(nil) }
    }
}

// MARK: - Present helper
extension UIApplication {
    static func presentOnRoot(_ vc: UIViewController) {
        guard let root = shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else { return }
        root.present(vc, animated: true)
    }
}
