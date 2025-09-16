import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MapKit
import CoreLocation

struct AddItemView: View {
    var preselectedCategoryId: String? = nil
    var preselectedCategoryName: String? = nil
    var preselectedCategoryColorHex: String? = nil

    // ✅ New preset values (from ScanView)
    var presetTitle: String? = nil
    var presetDescription: String? = nil
    var presetAmount: String? = nil
    var presetDate: Date? = nil

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    // Config
    private let creditMonthlyRate = 0.015

    // Categories
    @StateObject private var categoriesStore = CategoriesStore()
    @State private var selectedCategoryId: String?
    @State private var selectedCategoryName: String?
    @State private var selectedCategoryColorHex: String?

    // Form
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var warrantyExp: Date = Date()

    // Payment / status
    @State private var paymentMethod: String = "Wallet"
    @State private var status: String = "Paid"
    @State private var installments: Int = 3
    @State private var justSaveNoEffects = false

    // Location
    @State private var showLocationPicker = false
    @State private var locationName: String = ""
    @State private var latitude: Double?
    @State private var longitude: Double?

    // Wallet shortfall
    @State private var showShortfallSheet = false
    @State private var shortfallAmount: Double = 0
    @State private var shortfallInstallments: Int = 3
    @State private var pendingCatId: String = ""
    @State private var pendingCatName: String = ""

    // UI
    @State private var isSaving = false
    @State private var errorText: String?

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func creditInterest(principal: Double, months: Int) -> Double { principal * creditMonthlyRate * Double(months) }
    private func creditTotal(principal: Double, months: Int) -> Double { principal + creditInterest(principal: principal, months: months) }
    private func perInstallment(total: Double, months: Int) -> Double { months > 0 ? total / Double(months) : 0 }
    private var statusOptions: [String] { paymentMethod == "Credit" ? ["Pay", "To be paid"] : ["Paid", "Pay"] }

    var body: some View {
        Form {
            // Category
            Section(header: Text("Category")) {
                Picker("Select Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { newId in
                        selectedCategoryId = newId.isEmpty ? nil : newId
                        if let cat = categoriesStore.categories.first(where: { $0.id == newId }) {
                            selectedCategoryName = cat.name
                            selectedCategoryColorHex = cat.colorHex
                        }
                    }
                )) {
                    Text("Choose…").tag("")
                    ForEach(categoriesStore.categories) { c in
                        Text(c.name).tag(c.id ?? "")
                    }
                }
            }

            // Basic
            Section(header: Text("Basic Info")) {
                HStack {
                    Circle().fill(Color(hex: (selectedCategoryColorHex ?? preselectedCategoryColorHex ?? "#4F46E5"))).frame(width: 26, height: 26)
                    TextField("Title (e.g., Mixer, Phone)", text: $title).textInputAutocapitalization(.words)
                }
                TextField("Description", text: $description).textInputAutocapitalization(.sentences)
                HStack {
                    Text("Amount (LKR)"); Spacer()
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                DatePicker("Warranty Expiry", selection: $warrantyExp, displayedComponents: .date)
            }

            // Payment
            Section(header: Text("Payment")) {
                Picker("Method", selection: $paymentMethod) {
                    Text("Wallet").tag("Wallet")
                    Text("Credit").tag("Credit")
                }
                .onChange(of: paymentMethod) { new in status = (new == "Credit") ? "Pay" : "Paid" }

                Picker("Status", selection: $status) {
                    ForEach(statusOptions, id: \.self) { Text($0) }
                }

                if paymentMethod == "Credit" && status == "Pay" {
                    Picker("Term (months)", selection: $installments) {
                        Text("3").tag(3); Text("6").tag(6); Text("12").tag(12)
                    }
                    .pickerStyle(.segmented)

                    if let amt = amount {
                        let total = creditTotal(principal: amt, months: installments)
                        let pai = perInstallment(total: total, months: installments)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(format: "Interest: LKR %.2f", total - amt))
                            Text(String(format: "Total Payable: LKR %.2f", total)).bold()
                            Text(String(format: "Per Installment: LKR %.2f", pai)).foregroundColor(.appSecondaryTxt)
                        }
                    } else {
                        Text("Enter amount to see totals.").foregroundColor(.appSecondaryTxt)
                    }
                }

                Toggle("Just save (no deductions)", isOn: $justSaveNoEffects)
            }

            // Location
            Section(header: Text("Location")) {
                if let lat = latitude, let lng = longitude {
                    Text(locationName.isEmpty ? "Pinned location" : locationName).foregroundColor(.appSecondaryTxt)
                    Text(String(format: "Lat: %.5f, Lng: %.5f", lat, lng)).font(.caption).foregroundColor(.appSecondaryTxt)
                } else {
                    Text("No location selected").foregroundColor(.appSecondaryTxt)
                }
                Button { showLocationPicker = true } label: {
                    Label(latitude == nil ? "Add Location" : "Change Location", systemImage: "mappin.and.ellipse")
                }
                .buttonStyle(.bordered)
                .tint(Color.appBrand)
            }

            Section(header: Text("Note")) {
                TextField("Additional note…", text: $note, axis: .vertical)
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "Saving…" : "Save") { Task { await attemptSave() } }
                    .disabled(isSaving || !isFormValid)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            MapPickerView(initialName: locationName) { name, coord in
                locationName = name; latitude = coord.latitude; longitude = coord.longitude
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showShortfallSheet) {
            VStack(spacing: 16) {
                Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 44, height: 5).padding(.top, 10)
                Text("Insufficient Wallet Funds").font(.headline)
                Text(String(format: "You’re short by LKR %.2f.", shortfallAmount))
                Text("Move shortfall to Credit and pick a term:")
                Picker("Installments", selection: $shortfallInstallments) {
                    Text("3").tag(3); Text("6").tag(6); Text("12").tag(12)
                }
                .pickerStyle(.segmented)
                HStack {
                    Button("Cancel") { showShortfallSheet = false }
                    Spacer()
                    Button("Continue") {
                        Task {
                            showShortfallSheet = false
                            await finalizeSave(catId: pendingCatId, catName: pendingCatName, handleWalletShortfall: true)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal).padding(.bottom, 12)
            }
            .padding().presentationDetents([.height(260)]).presentationCornerRadius(20)
        }
        .alert("Error", isPresented: .constant(errorText != nil), actions: { Button("OK") { errorText = nil } },
               message: { Text(errorText ?? "") })
        .onAppear {
            NotificationManager.shared.requestAuthIfNeeded()

            // ✅ Fill presets if provided
            if let presetTitle = presetTitle, !presetTitle.isEmpty {
                title = presetTitle
            }
            if let presetDescription = presetDescription, !presetDescription.isEmpty {
                description = presetDescription
            }
            if let presetAmount = presetAmount, !presetAmount.isEmpty {
                amountText = presetAmount
            }
            if let presetDate = presetDate {
                date = presetDate
            }

            if selectedCategoryId == nil {
                if let pid = preselectedCategoryId {
                    selectedCategoryId = pid
                    selectedCategoryName = preselectedCategoryName
                    selectedCategoryColorHex = preselectedCategoryColorHex
                } else if let first = categoriesStore.categories.first {
                    selectedCategoryId = first.id
                    selectedCategoryName = first.name
                    selectedCategoryColorHex = first.colorHex
                }
            }
        }
    }

    // MARK: Save flow

    private var isFormValid: Bool {
        (selectedCategoryId != nil) &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount != nil && amount! >= 0
    }

    private func attemptSave() async {
        guard let uid = Auth.auth().currentUser?.uid else { errorText = "Not signed in."; return }
        guard let amt = amount else { errorText = "Enter a valid amount."; return }
        guard let catId = selectedCategoryId, let catName = selectedCategoryName else {
            errorText = "Please choose a category."; return
        }
        pendingCatId = catId; pendingCatName = catName

        if justSaveNoEffects {
            await finalizeSave(catId: catId, catName: catName, handleWalletShortfall: false); return
        }

        if paymentMethod == "Wallet" && (status == "Paid" || status == "Pay") {
            do {
                let wallet = try await fetchWalletBalance(uid: uid)
                if amt > wallet {
                    shortfallAmount = amt - wallet
                    shortfallInstallments = 3
                    showShortfallSheet = true
                    return
                }
            } catch {
                errorText = error.localizedDescription
                return
            }
        }

        await finalizeSave(catId: catId, catName: catName, handleWalletShortfall: false)
    }

    private func finalizeSave(catId: String, catName: String, handleWalletShortfall: Bool) async {
        guard let uid = Auth.auth().currentUser?.uid else { errorText = "Not signed in."; return }
        guard let amt = amount else { errorText = "Enter a valid amount."; return }

        isSaving = true
        do {
            // Base data
            var data: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
                "amount": amt,
                "note": note.trimmingCharacters(in: .whitespacesAndNewlines),
                "date": Timestamp(date: date),
                "warrantyExp": Timestamp(date: warrantyExp),
                "createdAt": FieldValue.serverTimestamp(),
                "categoryId": catId,
                "categoryName": catName
            ]
            if let lat = latitude, let lng = longitude {
                data["latitude"] = lat; data["longitude"] = lng; data["locationName"] = locationName
            }

            var itemIdWritten: String = ""

            switch paymentMethod {
            case "Wallet":
                if handleWalletShortfall {
                    let wallet = try await fetchWalletBalance(uid: uid)
                    let walletPaid = wallet
                    let creditPrincipal = max(amt - walletPaid, 0)
                    let ci = creditInterest(principal: creditPrincipal, months: shortfallInstallments)
                    let ctotal = creditPrincipal + ci
                    let cper = perInstallment(total: ctotal, months: shortfallInstallments)

                    data["paymentMethod"] = "Wallet+Credit"
                    data["status"] = "Pay"
                    data["walletPaid"] = walletPaid
                    data["creditPrincipal"] = creditPrincipal
                    data["creditInstallments"] = shortfallInstallments
                    data["creditInterestRate"] = creditMonthlyRate
                    data["creditInterestTotal"] = ci
                    data["creditTotalPayable"] = ctotal
                    data["creditPerInstallment"] = cper

                    itemIdWritten = try await writeItemAndEffects(uid: uid, catId: catId, itemData: data) {
                        try await incrementWalletBalance(uid: uid, by: -walletPaid)
                        try await incrementBudgetSpent(uid: uid, by: walletPaid)
                        try await incrementCreditUsed(uid: uid, by: ctotal)
                    }

                    try await createDues(uid: uid, itemId: itemIdWritten, categoryId: catId,
                                         itemTitle: title, totalMonths: shortfallInstallments,
                                         perInstallment: cper, purchaseDate: date, firstPaidNow: false)

                } else {
                    data["paymentMethod"] = "Wallet"; data["status"] = status
                    itemIdWritten = try await writeItemAndEffects(uid: uid, catId: catId, itemData: data) {
                        try await incrementWalletBalance(uid: uid, by: -amt)
                        if status == "Paid" || status == "Pay" {
                            try await incrementBudgetSpent(uid: uid, by: amt)
                        }
                    }
                }

            case "Credit":
                if status == "Pay" {
                    let total = creditTotal(principal: amt, months: installments)
                    let first = perInstallment(total: total, months: installments)
                    let wallet = try await fetchWalletBalance(uid: uid)
                    let walletUsed = min(wallet, first)
                    let creditImmediate = first - walletUsed
                    let creditRemaining = total - first

                    data["paymentMethod"] = "Credit"; data["status"] = "Pay"
                    data["installments"] = installments
                    data["interestMonthlyRate"] = creditMonthlyRate
                    data["interestTotal"] = (total - amt)
                    data["totalPayable"] = total
                    data["perInstallment"] = first

                    itemIdWritten = try await writeItemAndEffects(uid: uid, catId: catId, itemData: data) {
                        if walletUsed > 0 {
                            try await incrementWalletBalance(uid: uid, by: -walletUsed)
                            try await incrementBudgetSpent(uid: uid, by: walletUsed)
                        }
                        if creditImmediate > 0 { try await incrementCreditUsed(uid: uid, by: creditImmediate) }
                        try await incrementCreditUsed(uid: uid, by: creditRemaining)
                    }

                    try await createDues(uid: uid, itemId: itemIdWritten, categoryId: catId,
                                         itemTitle: title, totalMonths: installments - 1,
                                         perInstallment: first, purchaseDate: date, firstPaidNow: true)

                } else {
                    let total = creditTotal(principal: amt, months: installments)
                    let per = perInstallment(total: total, months: installments)

                    data["paymentMethod"] = "Credit"; data["status"] = "To be paid"
                    data["installments"] = installments
                    data["interestMonthlyRate"] = creditMonthlyRate
                    data["interestTotal"] = (total - amt)
                    data["totalPayable"] = total
                    data["perInstallment"] = per

                    itemIdWritten = try await writeItemAndEffects(uid: uid, catId: catId, itemData: data) {
                        try await incrementCreditUsed(uid: uid, by: total)
                    }

                    try await createDues(uid: uid, itemId: itemIdWritten, categoryId: catId,
                                         itemTitle: title, totalMonths: installments,
                                         perInstallment: per, purchaseDate: date, firstPaidNow: false)
                }

            default:
                data["paymentMethod"] = paymentMethod; data["status"] = status
                _ = try await writeItemAndEffects(uid: uid, catId: catId, itemData: data) { }
            }

            try await recomputeNetAfterExpenses(uid: uid)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        isSaving = false
    }

    // MARK: Firestore helpers

    private func writeItemAndEffects(uid: String, catId: String, itemData: [String: Any], effects: @escaping () async throws -> Void) async throws -> String {
        let itemRef = db.collection("users").document(uid)
            .collection("categories").document(catId)
            .collection("items").document()
        try await itemRef.setData(itemData)
        try await effects()
        return itemRef.documentID
    }

    private func incrementBudgetSpent(uid: String, by amount: Double) async throws {
        try await db.collection("users").document(uid).updateData(["financials.budgetSpent": FieldValue.increment(amount)])
    }
    private func incrementCreditUsed(uid: String, by amount: Double) async throws {
        try await db.collection("users").document(uid).updateData(["credit.used": FieldValue.increment(amount)])
    }
    private func incrementWalletBalance(uid: String, by amount: Double) async throws {
        try await db.collection("users").document(uid).updateData(["wallet.balance": FieldValue.increment(amount)])
    }

    private func fetchWalletBalance(uid: String) async throws -> Double {
        let snap = try await db.collection("users").document(uid).getDocument()
        let wallet = (snap.data()?["wallet"] as? [String: Any]) ?? [:]
        return wallet["balance"] as? Double ?? 0
    }

    private func recomputeNetAfterExpenses(uid: String) async throws {
        let ref = db.collection("users").document(uid)
        let snap = try await ref.getDocument()
        let f = snap.data()?["financials"] as? [String: Any] ?? [:]
        let income  = f["monthlyIncome"]   as? Double ?? 0
        let expenses = f["monthlyExpenses"] as? Double ?? 0
        let spent    = f["budgetSpent"]     as? Double ?? 0
        try await ref.updateData(["financials.netAfterExpenses": (income - expenses) - spent])
    }

    private func createDues(uid: String, itemId: String, categoryId: String, itemTitle: String,
                            totalMonths: Int, perInstallment: Double, purchaseDate: Date, firstPaidNow: Bool) async throws {
        guard totalMonths > 0 else { return }
        let duesRef = db.collection("users").document(uid).collection("dues")
        let cal = Calendar.current
        let base = cal.date(byAdding: .month, value: 1, to: purchaseDate) ?? purchaseDate

        for idx in 1...totalMonths {
            let dueDate = cal.date(byAdding: .month, value: idx - 1, to: base) ?? base
            let dueDoc = duesRef.document()
            try await dueDoc.setData([
                "itemId": itemId,
                "categoryId": categoryId,
                "itemTitle": itemTitle,
                "installmentIndex": firstPaidNow ? (idx + 1) : idx,
                "installments": firstPaidNow ? (totalMonths + 1) : totalMonths,
                "amount": perInstallment,
                "dueDate": Timestamp(date: dueDate),
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ])
            var at = cal.date(bySettingHour: 9, minute: 0, second: 0, of: dueDate) ?? dueDate
            if at < Date() { at = Date().addingTimeInterval(5) }
            NotificationManager.shared.schedule(
                id: dueDoc.documentID,
                title: "Installment due today",
                body: "\(itemTitle): LKR \(Int(perInstallment)) is due",
                on: at
            )
        }
    }
}
