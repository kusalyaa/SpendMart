import Foundation
import Vision
import UIKit

enum OCRService {
    static func recognizeText(from image: UIImage) async throws -> String {
        guard let cg = image.cgImage else { return "" }

        return try await withCheckedThrowingContinuation { cont in
            let req = VNRecognizeTextRequest { request, error in
                if let error = error { cont.resume(throwing: error); return }
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                cont.resume(returning: lines.joined(separator: "\n"))
            }
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = true
            req.recognitionLanguages = ["en-US", "en-GB"]

            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([req]) } catch { cont.resume(throwing: error) }
            }
        }
    }
}
