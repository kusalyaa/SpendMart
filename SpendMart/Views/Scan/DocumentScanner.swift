#if targetEnvironment(simulator)
import SwiftUI
struct DocumentScanner: View {
    var onComplete: (_ images: [UIImage]) -> Void
    var onCancel: () -> Void
    var onError: (_ error: Error) -> Void
    var body: some View { EmptyView() } // no camera in Simulator
}
#else
import SwiftUI
import VisionKit

struct DocumentScanner: UIViewControllerRepresentable {
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScanner
        init(_ parent: DocumentScanner) { self.parent = parent }

        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let imgs = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            c.dismiss(animated: true) { self.parent.onComplete(imgs) }
        }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) {
            c.dismiss(animated: true) { self.parent.onCancel() }
        }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError error: Error) {
            c.dismiss(animated: true) { self.parent.onError(error) }
        }
    }

    var onComplete: (_ images: [UIImage]) -> Void
    var onCancel: () -> Void
    var onError: (_ error: Error) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}
#endif
