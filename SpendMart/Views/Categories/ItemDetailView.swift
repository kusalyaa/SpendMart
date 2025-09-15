import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import MapKit

struct ItemDetailView: View {
    let categoryId: String
    let itemId: String
    let accentHex: String

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    @State private var item: Item?
    @State private var isLoading = true
    @State private var errorText: String?

    @State private var isEditing = false
    @State private var titleText = ""
    @State private var descriptionText = ""
    @State private var noteText = ""
    @State private var dateValue = Date()
    @State private var warrantyValue = Date()

    // edit-time location
    @State private var locationName = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showLocationPicker = false
    @State private var goViewMap = false

    // image
    @State private var imageURL: String?
    @State private var showImagePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Image header
                headerImage

                // Basic info
                card {
                    HStack {
                        Circle().fill(Color(hex: accentHex)).frame(width: 12, height: 12)
                        Text(item?.categoryName ?? "Category").font(.headline)
                        Spacer()
                        Text((item?.date ?? Date()).formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.secondary)
                    }

                    if isEditing {
                        TextField("Title", text: $titleText).font(.title3.weight(.semibold))
                        TextField("Description", text: $descriptionText)
                        DatePicker("Date", selection: $dateValue, displayedComponents: .date)
                        DatePicker("Warranty Expiry", selection: $warrantyValue, displayedComponents: .date)
                    } else {
                        Text(item?.title ?? "").font(.title3.weight(.semibold))
                        if let d = item?.description, !d.isEmpty { Text(d) }
                        if let w = item?.warrantyExp {
                            Text("Warranty until: \(w.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }

                // Payment (read-only)
                card {
                    VStack(alignment: .leading, spacing: 10) {
                        row("Amount", right: String(format: "LKR %.2f", item?.amount ?? 0), boldRight: true)
                        row("Method", right: item?.paymentMethod ?? "-")
                        row("Status", right: item?.status ?? "-")
                        if let m = item?.paymentMethod, m == "Credit" || m.contains("Credit") {
                            if let inst = item?.installments ?? item?.creditInstallments {
                                row("Installments", right: "\(inst)")
                            }
                            if let interest = item?.interestTotal ?? item?.creditInterestTotal {
                                row("Interest", right: String(format: "LKR %.2f", interest))
                            }
                            if let total = item?.totalPayable ?? item?.creditTotalPayable {
                                row("Total Payable", right: String(format: "LKR %.2f", total))
                            }
                            if let per = item?.perInstallment ?? item?.creditPerInstallment {
                                row("Per Installment", right: String(format: "LKR %.2f", per))
                            }
                            if let wp = item?.walletPaid, wp > 0 {
                                row("Wallet Paid", right: String(format: "LKR %.2f", wp))
                            }
                        }
                    }
                }

                // Location (button-only UI)
                card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location").font(.headline)
                        if isEditing {
                            Button {
                                showLocationPicker = true
                            } label: {
                                Label("Set / Change Location", systemImage: "mappin.and.ellipse")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: accentHex))

                            if let lat = latitude, let lng = longitude {
                                Text(locationName.isEmpty ? "Pinned location" : locationName)
                                    .foregroundColor(.secondary)
                                Text(String(format: "Lat: %.5f, Lng: %.5f", lat, lng))
                                    .font(.caption).foregroundColor(.secondary)
                            } else {
                                Text("No location selected").foregroundColor(.secondary)
                            }
                        } else {
                            let hasLoc = (item?.latitude != nil && item?.longitude != nil)
                            NavigationLink(isActive: $goViewMap) {
                                ItemLocationView(
                                    title: item?.locationName ?? "Location",
                                    latitude: item?.latitude ?? 0,
                                    longitude: item?.longitude ?? 0,
                                    accentHex: accentHex
                                )
                            } label: { EmptyView() }
                            .hidden()

                            Button {
                                if hasLoc { goViewMap = true }
                            } label: {
                                Label(hasLoc ? "View Location" : "No Location", systemImage: "map")
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(hex: accentHex))
                            .disabled(!hasLoc)
                        }
                    }
                }

                // Notes
                card {
                    if isEditing {
                        TextField("Note", text: $noteText, axis: .vertical).lineLimit(3...6)
                    } else {
                        Text(item?.note?.isEmpty == false ? item!.note! : "No note")
                            .foregroundColor(item?.note?.isEmpty == false ? .primary : .secondary)
                    }
                }
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Item")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isUploading { ProgressView() }
                Button { showImagePicker = true } label: { Image(systemName: "photo") }
                if isEditing {
                    Button("Save") { Task { await saveEdits() } }
                } else {
                    Button("Edit") { enterEditMode() }
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedPhoto) { _ in Task { await uploadSelectedImage() } }
        .sheet(isPresented: $showLocationPicker) {
            MapPickerView(initialName: locationName) { name, coord in
                locationName = name
                latitude = coord.latitude
                longitude = coord.longitude
            }
        }
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
        .onAppear { Task { await fetchItem() } }
    }

    // MARK: - UI helpers

    private var headerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color(hex: accentHex).opacity(0.12), .clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 220)

            if let urlStr = imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(height: 220)
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure: placeholderImage
                    @unknown default: placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground))
            VStack(spacing: 6) {
                Image(systemName: "photo").font(.system(size: 28))
                Text("No image").font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(height: 220)
    }

    @ViewBuilder private func card<Content: View>(@ViewBuilder _ c: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { c() }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }

    @ViewBuilder private func row(_ left: String, right: String, boldRight: Bool = false) -> some View {
        HStack {
            Text(left).foregroundColor(.secondary)
            Spacer()
            Text(right).font(boldRight ? .body.weight(.semibold) : .body)
        }
    }

    private func enterEditMode() {
        guard let it = item else { return }
        isEditing = true
        titleText = it.title
        descriptionText = it.description ?? ""
        noteText = it.note ?? ""
        dateValue = it.date
        warrantyValue = it.warrantyExp ?? Date()
        locationName = it.locationName ?? ""
        latitude = it.latitude
        longitude = it.longitude
    }

    // MARK: - Data

    private func fetchItem() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let doc = try await db.collection("users").document(uid)
                .collection("categories").document(categoryId)
                .collection("items").document(itemId).getDocument()
            let x = doc.data() ?? [:]
            let it = Item(
                id: doc.documentID,
                title: x["title"] as? String ?? "Item",
                description: x["description"] as? String,
                amount: x["amount"] as? Double ?? 0,
                note: x["note"] as? String,
                date: (x["date"] as? Timestamp)?.dateValue() ?? Date(),
                createdAt: (x["createdAt"] as? Timestamp)?.dateValue(),
                categoryId: x["categoryId"] as? String,
                categoryName: x["categoryName"] as? String,
                paymentMethod: x["paymentMethod"] as? String,
                status: x["status"] as? String,
                installments: x["installments"] as? Int,
                interestMonthlyRate: x["interestMonthlyRate"] as? Double,
                interestTotal: x["interestTotal"] as? Double,
                totalPayable: x["totalPayable"] as? Double,
                perInstallment: x["perInstallment"] as? Double,
                walletPaid: x["walletPaid"] as? Double,
                creditPrincipal: x["creditPrincipal"] as? Double,
                creditInstallments: x["creditInstallments"] as? Int,
                creditInterestRate: x["creditInterestRate"] as? Double,
                creditInterestTotal: x["creditInterestTotal"] as? Double,
                creditTotalPayable: x["creditTotalPayable"] as? Double,
                creditPerInstallment: x["creditPerInstallment"] as? Double,
                locationName: x["locationName"] as? String,
                latitude: x["latitude"] as? Double,
                longitude: x["longitude"] as? Double,
                warrantyExp: (x["warrantyExp"] as? Timestamp)?.dateValue(),
                imageURL: x["imageURL"] as? String
            )
            await MainActor.run {
                item = it
                imageURL = it.imageURL
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorText = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func saveEdits() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard isEditing else { return }
        do {
            var updates: [String: Any] = [
                "title": titleText.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                "note": noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                "date": Timestamp(date: dateValue),
                "warrantyExp": Timestamp(date: warrantyValue)
            ]
            if let lat = latitude, let lng = longitude {
                updates["latitude"] = lat
                updates["longitude"] = lng
                updates["locationName"] = locationName
            } else {
                updates["latitude"] = FieldValue.delete()
                updates["longitude"] = FieldValue.delete()
                updates["locationName"] = FieldValue.delete()
            }

            try await db.collection("users").document(uid)
                .collection("categories").document(categoryId)
                .collection("items").document(itemId)
                .updateData(updates)

            isEditing = false
            await fetchItem()
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func uploadSelectedImage() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let selectedPhoto else { return }
        isUploading = true
        defer { isUploading = false }

        do {
            guard
                let data = try await selectedPhoto.loadTransferable(type: Data.self),
                let img = UIImage(data: data),
                let jpeg = img.jpegData(compressionQuality: 0.85)
            else { return }

            let storage = Storage.storage()
            let path = "users/\(uid)/categories/\(categoryId)/items/\(itemId).jpg"
            let ref = storage.reference(withPath: path)
            let meta = StorageMetadata()
            meta.contentType = "image/jpeg"

            _ = try await ref.putDataAsync(jpeg, metadata: meta)
            let url = try await ref.downloadURL()

            try await db.collection("users").document(uid)
                .collection("categories").document(categoryId)
                .collection("items").document(itemId)
                .updateData(["imageURL": url.absoluteString])

            await MainActor.run { imageURL = url.absoluteString }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }
}

private var placeholderImage: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground))
        VStack(spacing: 6) {
            Image(systemName: "photo").font(.system(size: 28))
            Text("No image").font(.caption).foregroundColor(.secondary)
        }
    }
    .frame(height: 220)
}
