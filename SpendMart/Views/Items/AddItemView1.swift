import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum ItemType: String, CaseIterable, Identifiable { case product = "Product", service = "Service"; var id: String { rawValue } }
enum PayStatus: String, CaseIterable, Identifiable { case paid = "Paid", due = "To be paid"; var id: String { rawValue } }

struct AddItemView1: View {
    
    var presetName: String = ""
    var presetAmountText: String = ""
    var presetDate: Date = Date()
    var presetRawText: String = ""

    @Environment(\.dismiss) private var dismiss

    
    @State private var name = ""
    @State private var selectedCategory = "Category"
    @State private var type: ItemType = .product
    @State private var status: PayStatus = .paid
    @State private var amountText = ""
    @State private var date = Date()
    @State private var warrantyExpDate = Date().addingTimeInterval(60*60*24*365)

    
    @State private var showLocationSheet = false
    @State private var locationLabel = ""

    @State private var saving = false
    @State private var error: String?

    private let categories = ["Electronics","Appliances","Furniture","Clothing","Books","Other"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.85)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 6)

                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 64, height: 64)
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Item")
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            Text("Create an expense entry")
                                .foregroundColor(.white.opacity(0.95))
                        }
                        Spacer()
                    }
                    .padding(16)
                }
                .frame(height: 100)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                
                Card {
                    fieldLabel("Name")
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    fieldLabel("Category")
                    Menu {
                        ForEach(categories, id: \.self) { c in
                            Button(c) { selectedCategory = c }
                        }
                    } label: {
                        pickerLabel(selectedCategory)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Type")
                            Picker("", selection: $type) {
                                ForEach(ItemType.allCases) { t in Text(t.rawValue).tag(t) }
                            }
                            .pickerStyle(.segmented)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Status")
                            Picker("", selection: $status) {
                                ForEach(PayStatus.allCases) { s in Text(s.rawValue).tag(s) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    fieldLabel("Amount (LKR)")
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                
                Card {
                    HStack {
                        Image(systemName: "calendar").foregroundStyle(.secondary)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Divider()
                    HStack {
                        Image(systemName: "calendar.badge.clock").foregroundStyle(.secondary)
                        DatePicker("Warranty Exp. (optional)", selection: $warrantyExpDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }

                
                Card {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationLabel.isEmpty ? "No location set" : locationLabel)
                                .fontWeight(.semibold)
                            Text("Optional").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            showLocationSheet = true
                        } label: {
                            Label(locationLabel.isEmpty ? "Add Location" : "Change",
                                  systemImage: "plus")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                
                VStack(spacing: 12) {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if saving { ProgressView() }
                            Text(saving ? "Saving…" : "Save").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .disabled(!canSave || saving)
                    .background(canSave ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(14)

                    Button("Cancel") { dismiss() }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)

                if let error {
                    Text(error).foregroundStyle(.red).padding(.horizontal, 16)
                }

                Spacer(minLength: 24)
            }
        }
        .onAppear {
            name = presetName
            amountText = presetAmountText
            date = presetDate
        }
        .sheet(isPresented: $showLocationSheet) {
            LocationLabelSheet(initial: locationLabel) { newLabel in
                locationLabel = newLabel
            }
            .presentationDetents([.height(240)])
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: "")) else { return }
        saving = true; error = nil
        do {
            try await ExpenseService.addExpense(
                title: name,
                amount: amount,
                when: date,
                categoryId: nil,
                categoryName: selectedCategory == "Category" ? nil : selectedCategory,
                itemType: type.rawValue,
                status: status.rawValue,
                warrantyExp: warrantyExpDate,
                locationName: locationLabel.isEmpty ? nil : locationLabel,
                latitude: nil,
                longitude: nil,
                source: presetRawText.isEmpty ? "manual" : "scan",
                rawText: presetRawText
            )
            saving = false
            dismiss()
        } catch {
            saving = false
            self.error = error.localizedDescription
        }
    }

    @ViewBuilder private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(.secondary)
    }

    @ViewBuilder private func pickerLabel(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(title == "Category" ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.down").foregroundStyle(.secondary).font(.caption)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.35)))
    }
}


fileprivate struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
            .padding(.horizontal, 16)
    }
}


fileprivate struct LocationLabelSheet: View {
    var initial: String
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TextField("Enter a location label (e.g. Supermarket, Home)", text: $label)
                    .textFieldStyle(.roundedBorder)
                Spacer()
                HStack {
                    Button("Cancel") { dismiss() }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(10)

                    Button("Save") {
                        onSave(label.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { label = initial }
    }
}
