import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ManageEmergencyFundView: View {
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    // Live values fetched on appear (to compute free cash correctly)
    @State private var income: Double = 0
    @State private var expenses: Double = 0
    @State private var budget: Double = 0
    @State private var emergencyFund: Double = 0

    @State private var amountText = ""
    @State private var isWorking = false
    @State private var errorText: String?

    private var freeCash: Double {
        max((income - expenses) - budget - emergencyFund, 0)
    }

    var body: some View {
        Form {
            Section(header: Text("Current Totals")) {
                row("Monthly Income", value: income)
                row("Monthly Expenses", value: expenses)
                row("Monthly Budget", value: budget)
                row("Emergency Fund", value: emergencyFund)
                HStack {
                    Text("Free Cash").font(.headline)
                    Spacer()
                    Text("LKR \(Int(freeCash))").font(.headline)
                }
            }

            Section(header: Text("Add Emergency Fund")) {
                HStack {
                    Text("Amount (LKR)")
                    Spacer()
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                Button(isWorking ? "Adding…" : "Add from Free Cash") {
                    Task { await addToEF() }
                }
                .disabled(isWorking || (Double(amountText) ?? 0) <= 0 || (Double(amountText) ?? 0) > freeCash)
                .buttonStyle(.borderedProminent)
                .tint(Color.appBrand)

                Text("We only allow adding Emergency Fund from your Free Cash (Income − Expenses − Budget). This does not change your budget or spent totals.")
                    .font(.caption)
                    .foregroundColor(.appSecondaryTxt)
            }

            Section(header: Text("Optional")) {
                Button(isWorking ? "Releasing…" : "Release EF back to Free Cash") {
                    Task { await releaseAllEF() }
                }
                .buttonStyle(.bordered)
                .disabled(isWorking || emergencyFund <= 0)
            }
        }
        .navigationTitle("Emergency Fund")
        .onAppear { Task { await load() } }
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
    }

    private func row(_ label: String, value: Double) -> some View {
        HStack { Text(label); Spacer(); Text("LKR \(Int(value))") }
    }

    private func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            let f = snap.data()?["financials"] as? [String: Any] ?? [:]
            income       = f["monthlyIncome"]   as? Double ?? 0
            expenses     = f["monthlyExpenses"] as? Double ?? 0
            budget       = f["monthlyBudget"]   as? Double ?? 0
            emergencyFund = f["emergencyFund"]  as? Double ?? 0
        } catch {
            errorText = error.localizedDescription
        }
    }

    // Add to EF (from Free Cash). We just bump EF; budget/spent untouched.
    private func addToEF() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let add = Double(amountText), add > 0, add <= freeCash else { return }
        isWorking = true
        do {
            try await db.collection("users").document(uid).updateData([
                "financials.emergencyFund": FieldValue.increment(add)
            ])
            emergencyFund += add
            amountText = ""
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }

    // Release all EF back to free cash (again: we just reduce EF value)
    private func releaseAllEF() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let release = emergencyFund
        guard release > 0 else { return }
        isWorking = true
        do {
            try await db.collection("users").document(uid).updateData([
                "financials.emergencyFund": FieldValue.increment(-release)
            ])
            emergencyFund = 0
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }
}
