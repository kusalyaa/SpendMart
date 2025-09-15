import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class CategoriesStore: ObservableObject {
    
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()

    init() { listen() }

    private func listen() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("categories")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, err in
                if let err = err { print("⚠️ categories listen:", err); return }
                let docs = snap?.documents ?? []
                self?.categories = docs.map { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unnamed"
                    let colorHex = data["colorHex"] as? String ?? "#4F46E5"
                    let ts = data["createdAt"] as? Timestamp
                    return Category(
                        id: doc.documentID,
                        name: name,
                        colorHex: colorHex,
                        createdAt: ts?.dateValue()
                    )
                    
                }
            }
    }

    func addCategory(named name: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let colorHex = Color.tilePaletteHex.randomElement() ?? "#4F46E5"
        let col = db.collection("users").document(uid).collection("categories")
        let doc = col.document()
        try await doc.setData([
            "name": name,
            "colorHex": colorHex,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
}

struct CategoriesView: View {
    @StateObject private var store = CategoriesStore()
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var isSaving = false
    @State private var errorText: String?

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(store.categories) { cat in
                        NavigationLink {
                            CategoryDetailView(category: cat)
                        } label: {
                            CategoryTile(cat: cat)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 90)
            }

            AddButton { showingAdd = true }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
        }
        // Title from parent NavigationStack/NavigationView
        .navigationTitle("Categories")
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
        .sheet(isPresented: $showingAdd) {
            NewCategorySheet(
                name: $newName,
                isSaving: $isSaving,
                onCancel: {
                    newName = ""
                    showingAdd = false
                },
                onSave: { name in
                    Task {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        isSaving = true
                        do {
                            try await store.addCategory(named: trimmed)
                            newName = ""
                            showingAdd = false
                        } catch {
                            errorText = error.localizedDescription
                        }
                        isSaving = false
                    }
                }
            )
            .presentationDetents([.height(220)])
            .presentationCornerRadius(20)
        }
    }
}

private struct CategoryTile: View {
    let cat: Category

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: cat.colorHex))
                .frame(height: 110)
                .overlay(
                    Text(String(cat.name.prefix(1)).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

            Text(cat.name)
                .font(.subheadline)
                .foregroundColor(.appSecondaryTxt)
                .lineLimit(1)
        }
    }
}

private struct AddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.appBrand)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 8)
        }
        .accessibilityLabel("Add Category")
    }
}


private struct NewCategorySheet: View {
    @Binding var name: String
    @Binding var isSaving: Bool
    var onCancel: () -> Void
    var onSave: (_ name: String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 44, height: 5).padding(.top, 10)

            Text("New Category")
                .font(.headline)

            TextField("Enter category name", text: $name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button(isSaving ? "Saving…" : "OK") {
                    onSave(name)
                }
                .disabled(isSaving)
                .font(.headline)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}
