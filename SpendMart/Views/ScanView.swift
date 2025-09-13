//import SwiftUI
//import PDFKit
//import UniformTypeIdentifiers
//import UIKit
//
//struct ScanView: View {
//    @State private var showScanner = false
//    @State private var showDocPicker = false
//
//    // Prefill for Add Item
//    @State private var goAddItem = false
//    @State private var prefName = ""
//    @State private var prefAmountText = ""
//    @State private var prefDate = Date()
//    @State private var prefRawText = ""
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 18) {
//                // Header
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Scan").font(.system(size: 34, weight: .bold))
//                    Text("Add expenses from receipts").foregroundStyle(.secondary)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 16)
//                .padding(.top, 8)
//
//                // Buttons panel
//                VStack(spacing: 12) {
//                    #if !targetEnvironment(simulator)
//                    Button {
//                        showScanner = true
//                    } label: {
//                        HStack(spacing: 10) {
//                            Image(systemName: "doc.viewfinder")
//                            Text("Scan with Camera").fontWeight(.semibold)
//                        }
//                        .frame(maxWidth: .infinity, minHeight: 52)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    #endif
//
//                    Button {
//                        showDocPicker = true
//                    } label: {
//                        HStack(spacing: 10) {
//                            Image(systemName: "doc.text.viewfinder")
//                            Text("Choose Image or PDF").fontWeight(.semibold)
//                        }
//                        .frame(maxWidth: .infinity, minHeight: 52)
//                    }
//                    .buttonStyle(.borderedProminent)
//
//                    Button {
//                        goAddItem = true
//                    } label: {
//                        HStack(spacing: 10) {
//                            Image(systemName: "square.and.pencil")
//                            Text("Add Manually").fontWeight(.semibold)
//                        }
//                        .frame(maxWidth: .infinity, minHeight: 52)
//                    }
//                    .buttonStyle(.bordered)
//
//                    #if targetEnvironment(simulator)
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground))
//                        VStack(spacing: 8) {
//                            Image(systemName: "camera.viewfinder").font(.largeTitle).foregroundStyle(.secondary)
//                            Text("Camera scanning is unavailable in Simulator. Choose Image/PDF or Add Manually.")
//                                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
//                                .padding(.horizontal, 16)
//                        }
//                    }
//                    .frame(height: 140)
//                    #endif
//                }
//                .padding(16)
//                .background(Color(.secondarySystemBackground))
//                .cornerRadius(16)
//                .padding(.horizontal, 16)
//
//                Spacer()
//
//                // Hidden link to Add Item
//                NavigationLink("", isActive: $goAddItem) {
//                    AddItemView(
//                        presetName: prefName,
//                        presetAmountText: prefAmountText,
//                        presetDate: prefDate,
//                        presetRawText: prefRawText
//                    )
//                }.hidden()
//            }
//            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
//        }
//        // VisionKit camera (device only; stub does nothing on Simulator)
//        .sheet(isPresented: $showScanner) {
//            DocumentScanner(
//                onComplete: { images in
//                    showScanner = false
//                    handle(images.first)
//                },
//                onCancel: { showScanner = false },
//                onError: { _ in showScanner = false }
//            )
//        }
//        // Files (PDF or image) – works great in Simulator
//        .sheet(isPresented: $showDocPicker) {
//            DocumentPicker { url in
//                showDocPicker = false
//                if let img = renderFirstPageOrImage(from: url) { handle(img) }
//            }
//        }
//    }
//
//    // MARK: - Pipeline
//
//    private func handle(_ image: UIImage?) {
//        guard let image else { return }
//        Task {
//            do {
//                let text = try await OCRService.recognizeText(from: image)
//                let parsed = ReceiptParser.parse(text: text)
//                prefName = parsed.merchant
//                prefAmountText = parsed.amount > 0 ? String(format: "%.2f", parsed.amount) : ""
//                prefDate = parsed.date ?? Date()
//                prefRawText = text
//                goAddItem = true
//            } catch {
//                prefName = ""; prefAmountText = ""; prefDate = Date(); prefRawText = ""
//                goAddItem = true
//            }
//        }
//    }
//
//    private func renderFirstPageOrImage(from url: URL) -> UIImage? {
//        guard url.startAccessingSecurityScopedResource() else { return nil }
//        defer { url.stopAccessingSecurityScopedResource() }
//
//        if url.pathExtension.lowercased() == "pdf",
//           let doc = PDFDocument(url: url),
//           let page = doc.page(at: 0) {
//            let rect = page.bounds(for: .mediaBox)
//            let scale: CGFloat = 2
//            let size = CGSize(width: rect.width * scale, height: rect.height * scale)
//            UIGraphicsBeginImageContext(size)
//            guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
//            ctx.saveGState()
//            ctx.scaleBy(x: scale, y: scale)
//            ctx.translateBy(x: 0, y: rect.size.height)
//            ctx.scaleBy(x: 1, y: -1)
//            page.draw(with: .mediaBox, to: ctx)
//            ctx.restoreGState()
//            let img = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            return img
//        } else if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
//            return img
//        }
//        return nil
//    }
//}





import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers
#if !targetEnvironment(simulator)
import VisionKit
#endif

struct ScanView: View {
    @EnvironmentObject private var session: AppSession

    #if !targetEnvironment(simulator)
    @State private var showScanner = false
    #endif
    @State private var photoItem: PhotosPickerItem?
    @State private var showDocPicker = false

    // Prefilled Add Item sheet
    @State private var showAddSheet = false
    @State private var presetName = ""
    @State private var presetAmountText = ""
    @State private var presetDate = Date()
    @State private var presetRawText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan").font(.system(size: 34, weight: .bold))
                    Text("Add expenses from receipts").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    #if !targetEnvironment(simulator)
                    Button {
                        session.suppressAuthRouting = true
                        showScanner = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.viewfinder")
                            Text("Scan with Camera").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    #endif

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose Image").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        session.suppressAuthRouting = true
                        showDocPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text")
                            Text("Import PDF").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)

                    #if targetEnvironment(simulator)
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground))
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder").font(.largeTitle).foregroundStyle(.secondary)
                            Text("Camera scanning isn’t available in Simulator.\nUse Image/PDF instead.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 16)
                        }
                    }.frame(height: 140)
                    #endif
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        }
        // Photos result → OCR → prefill
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                session.suppressAuthRouting = true
                defer { session.suppressAuthRouting = false }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImg = UIImage(data: data) {
                    await handleImage(uiImg)
                }
                photoItem = nil
            }
        }
        // PDF / images (UIDocumentPicker)
        .sheet(isPresented: $showDocPicker, onDismiss: { session.suppressAuthRouting = false }) {
            DocumentPicker { url in
                showDocPicker = false
                if let img = renderFirstPageOrImage(from: url) {
                    Task { await handleImage(img) }
                }
                // session.suppressAuthRouting reset occurs in onDismiss
            }
        }
        // VisionKit camera (device)
        #if !targetEnvironment(simulator)
        .sheet(isPresented: $showScanner, onDismiss: { session.suppressAuthRouting = false }) {
            DocumentScanner(
                onComplete: { images in
                    showScanner = false
                    if let first = images.first {
                        Task { await handleImage(first) }
                    }
                },
                onCancel: { showScanner = false },
                onError: { _ in showScanner = false }
            )
        }
        #endif
        // Add Item sheet (user can Save or Cancel)
        .sheet(isPresented: $showAddSheet) {
            AddItemView(
                presetName: presetName,
                presetAmountText: presetAmountText,
                presetDate: presetDate,
                presetRawText: presetRawText
            )
        }
    }

    // MARK: OCR → Prefill
    @MainActor
    private func handleImage(_ image: UIImage) async {
        do {
            let text = try await OCRService.recognizeText(from: image)
            let parsed = ReceiptParser.parse(text: text)
            presetName = parsed.merchant
            presetAmountText = parsed.amount > 0 ? String(format: "%.2f", parsed.amount) : ""
            presetDate = parsed.date ?? Date()
            presetRawText = text
            showAddSheet = true
        } catch {
            presetName = ""; presetAmountText = ""; presetDate = Date(); presetRawText = ""
            showAddSheet = true
        }
    }

    private func renderFirstPageOrImage(from url: URL) -> UIImage? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        if url.pathExtension.lowercased() == "pdf",
           let doc = PDFDocument(url: url),
           let page = doc.page(at: 0) {
            let rect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2
            let size = CGSize(width: rect.width * scale, height: rect.height * scale)
            UIGraphicsBeginImageContext(size)
            guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: 0, y: rect.size.height)
            ctx.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: ctx)
            ctx.restoreGState()
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        } else if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            return img
        }
        return nil
    }
}
