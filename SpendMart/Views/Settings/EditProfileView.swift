import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    let currentName: String
    let currentPhone: String
    let currentAddress: String

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var isSaving = false
    @State private var errorText: String?

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Address", text: $address, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appBrand)
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            name = currentName
            phone = currentPhone
            address = currentAddress
        }
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
    }

    private func save() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        do {
            try await db.collection("users").document(uid).setData([
                "profile": [
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
                    "address": address.trimmingCharacters(in: .whitespacesAndNewlines)
                ]
            ], merge: true)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        isSaving = false
    }
}
