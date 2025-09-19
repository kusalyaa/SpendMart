import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MapKit

final class ItemsStore: ObservableObject {
    @Published var items: [Item] = []
    private let db = Firestore.firestore()

    func listen(categoryId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid)
            .collection("categories").document(categoryId)
            .collection("items")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                if let err = err { print("⚠️ items listen:", err); return }
                let docs = snap?.documents ?? []
                self?.items = docs.map { d in
                    let x = d.data()
                    return Item(
                        id: d.documentID,
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
                }
            }
    }
}

struct CategoryDetailView: View {
    let category: Category
    @StateObject private var store = ItemsStore()

    @State private var goToAdd = false
    private var categoryId: String { category.id ?? "" }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                if store.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundColor(.appSecondaryTxt)
                        Text("No items in this category yet")
                            .foregroundColor(.appSecondaryTxt)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(store.items) { it in
                        NavigationLink {
                            ItemDetailView(categoryId: categoryId,
                                           itemId: it.id ?? "",
                                           accentHex: category.colorHex)
                        } label: {
                            HStack(spacing: 12) {
                                // Thumbnail if exists
                                if let urlStr = it.imageURL, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty: ProgressView().frame(width: 44, height: 44)
                                        case .success(let img): img.resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                        case .failure: thumbPlaceholder
                                        @unknown default: thumbPlaceholder
                                        }
                                    }
                                } else {
                                    thumbPlaceholder
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(it.title).font(.body)
                                    if let status = it.status, let method = it.paymentMethod {
                                        Text("\(method) • \(status)")
                                            .font(.caption)
                                            .foregroundColor(.appSecondaryTxt)
                                    }
                                    if let note = it.note, !note.isEmpty {
                                        Text(note).font(.caption2).foregroundColor(.appSecondaryTxt)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(String(format: "LKR %.2f", it.amount))
                                        .font(.subheadline).bold()
                                    if let tp = it.totalPayable, tp > it.amount {
                                        Text(String(format: "Total: LKR %.2f", tp))
                                            .font(.caption2).foregroundColor(.appSecondaryTxt)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)

            Button {
                goToAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.appBrand)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 28)

            NavigationLink(isActive: $goToAdd) {
                AddItemView(
                    preselectedCategoryId: categoryId,
                    preselectedCategoryName: category.name,
                    preselectedCategoryColorHex: category.colorHex
                )
            } label: { EmptyView() }
            .hidden()
        }
        .navigationTitle(category.name)
        .onAppear {
            if !categoryId.isEmpty { store.listen(categoryId: categoryId) }
        }
    }

    private var thumbPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
            Image(systemName: "doc.text.image").foregroundColor(.secondary)
        }
        .frame(width: 44, height: 44)
    }
}


struct ItemLocationView: View {
    let title: String
    let latitude: Double
    let longitude: Double
    let accentHex: String

    var body: some View {
        ReadOnlyMapView(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01),
            markerTint: UIColor(Color(hex: accentHex))
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
