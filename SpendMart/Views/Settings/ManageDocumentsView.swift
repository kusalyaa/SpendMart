import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

enum DocCategory: String, CaseIterable, Identifiable {
    case nic = "NIC/ID"
    case utility = "Utility Bill"
    case statement = "Account Statement"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .nic: return "person.text.rectangle"
        case .utility: return "bolt.fill"
        case .statement: return "banknote.fill"
        }
    }
    var key: String {
        switch self {
        case .nic: return "nic"
        case .utility: return "utility"
        case .statement: return "statement"
        }
    }
}

struct AppDocument: Identifiable {
    var id: String
    var name: String
    var url: String
    var uploadedAt: Date
    var category: String   // "nic" | "utility" | "statement"
}

final class DocumentsVM: ObservableObject {
    @Published var docs: [AppDocument] = []
    private let db = Firestore.firestore()

    func listen() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("documents")
            .order(by: "uploadedAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                if let err = err { print("⚠️ docs listen:", err); return }
                let arr = (snap?.documents ?? []).map { d -> AppDocument in
                    let x = d.data()
                    return AppDocument(
                        id: d.documentID,
                        name: x["name"] as? String ?? "Document",
                        url: x["url"] as? String ?? "",
                        uploadedAt: (x["uploadedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        category: x["category"] as? String ?? "other"
                    )
                }
                self?.docs = arr
            }
    }
}

struct ManageDocumentsView: View {
    @StateObject private var vm = DocumentsVM()

    @State private var selectedCategory: DocCategory? = nil
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    @State private var isUploading = false
    @State private var errorText: String?

    var body: some View {
        List {
            // Picker tiles
            Section(header: Text("Choose a Category")) {
                HStack(spacing: 12) {
                    ForEach(DocCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                Text(cat.rawValue)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedCategory == cat ? Color.appBrand : .secondary)
                    }
                }
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Upload Image", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appBrand)
                .disabled(selectedCategory == nil)
                if isUploading { ProgressView("Uploading…") }
                if let sel = selectedCategory {
                    Text("Selected: \(sel.rawValue)")
                        .font(.caption)
                        .foregroundColor(.appSecondaryTxt)
                }
            }

            // List by category groups
            ForEach(DocCategory.allCases) { cat in
                Section(header: Text(cat.rawValue)) {
                    let items = vm.docs.filter { $0.category == cat.key }
                    if items.isEmpty {
                        Text("No \(cat.rawValue.lowercased()) uploaded.")
                            .foregroundColor(.appSecondaryTxt)
                    } else {
                        ForEach(items) { doc in
                            Link(destination: URL(string: doc.url)!) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
                                        Image(systemName: cat.icon).foregroundColor(.secondary)
                                    }
                                    .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.name).lineLimit(1)
                                        Text(doc.uploadedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption).foregroundColor(.appSecondaryTxt)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.circle").foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.listen() }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedPhoto) { _ in Task { await uploadSelectedPhoto() } }
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
    }

    // MARK: Upload

    private func uploadSelectedPhoto() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let selectedPhoto, let cat = selectedCategory else { return }
        isUploading = true
        defer { isUploading = false }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else { return }

            let storage = Storage.storage()
            let fileId = UUID().uuidString
            let path = "users/\(uid)/documents/\(cat.key)/\(fileId).jpg"
            let ref = storage.reference(withPath: path)
            let meta = StorageMetadata(); meta.contentType = "image/jpeg"

            _ = try await ref.putDataAsync(data, metadata: meta)
            let url = try await ref.downloadURL()

            try await Firestore.firestore().collection("users").document(uid)
                .collection("documents").document(fileId)
                .setData([
                    "name": "\(cat.rawValue) \(fileId.prefix(6))",
                    "url": url.absoluteString,
                    "uploadedAt": FieldValue.serverTimestamp(),
                    "category": cat.key,
                    "type": "image"
                ])
        } catch {
            errorText = error.localizedDescription
        }
    }
}
