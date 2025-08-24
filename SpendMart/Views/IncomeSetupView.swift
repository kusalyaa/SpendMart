import SwiftUI
import FirebaseAuth

// ✅ Move the timeout error OUTSIDE any closure/generic context
private enum TimeoutError: Error { case timedOut }

enum BudgetMode: String, CaseIterable, Identifiable {
    case custom = "Custom amount"
    case percentage = "Percentage of (Income − Expenses)"
    var id: String { rawValue }
}

struct IncomeSetupView: View {
    // MARK: - UI State
    @State private var monthlyIncomeText: String = ""
    @State private var monthlyExpensesText: String = ""
    @State private var budgetMode: BudgetMode = .percentage
    @State private var percentage: Double = 30
    @State private var customBudgetText: String = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goToNext = false   // -> LoginView()

    // MARK: - Derived
    private var income: Double {
        Double(monthlyIncomeText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var expenses: Double {
        Double(monthlyExpensesText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var netAfterExpenses: Double { max(income - expenses, 0) }
    private var budget: Double {
        switch budgetMode {
        case .custom:
            return Double(customBudgetText.replacingOccurrences(of: ",", with: "")) ?? 0
        case .percentage:
            return (netAfterExpenses * (percentage / 100.0))
        }
    }
    private var budgetValid: Bool { budget <= netAfterExpenses }
    private var canSave: Bool {
        income > 0 && expenses >= 0 && budget >= 0 && budgetValid
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (tight)
                VStack(spacing: 12) {
                    Text("Income & Budget")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.top, 20)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue)
                            .frame(width: 68, height: 68)
                        Text("$")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 12)

                // Content
                ScrollView {
                    VStack(spacing: 14) {

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Monthly Income")
                                    .font(.headline)
                                currencyField("Enter income", text: $monthlyIncomeText)
                                Text("This is your total expected income for the month.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Monthly Expenses")
                                    .font(.headline)
                                currencyField("Enter total expenses", text: $monthlyExpensesText)
                                Text("All fixed/recurring bills and typical monthly costs.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Monthly Budget")
                                    .font(.headline)

                                Picker("", selection: $budgetMode) {
                                    ForEach(BudgetMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if budgetMode == .percentage {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Use")
                                            Text("\(Int(percentage))%")
                                                .fontWeight(.semibold)
                                            Text("of Income − Expenses")
                                        }
                                        Slider(value: $percentage, in: 0...100, step: 1)
                                        HStack {
                                            Text("Net After Expenses")
                                            Spacer()
                                            Text(formatCurrency(netAfterExpenses))
                                                .fontWeight(.semibold)
                                        }
                                    }
                                } else {
                                    currencyField("Enter custom monthly budget", text: $customBudgetText)
                                }

                                Divider().padding(.vertical, 2)

                                VStack(spacing: 6) {
                                    summaryRow(label: "Income", value: income)
                                    summaryRow(label: "Expenses", value: expenses)
                                    summaryRow(label: "Net After Expenses", value: netAfterExpenses)
                                    summaryRow(label: "Budget", value: budget)

                                    if !budgetValid {
                                        Text("Budget cannot exceed Net After Expenses.")
                                            .font(.footnote)
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }

                        Button {
                            saveAndGo()
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving { ProgressView().controlSize(.regular) }
                                Text(isSaving ? "Saving…" : "Save & Continue")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(!canSave || isSaving)
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .alert("Notice", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: { Text(alertMessage) })
            .fullScreenCover(isPresented: $goToNext) {
                // Go where you want after setup:
                LoginView()    // or RootTabView()
            }
        }
    }

    // MARK: - Save that never blocks UI
    private func saveAndGo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            alertMessage = "You’re not signed in."
            showAlert = true
            return
        }
        guard canSave else {
            alertMessage = "Please check your inputs."
            showAlert = true
            return
        }

        isSaving = true

        // 1) Navigate immediately for snappy UX
        goToNext = true

        // 2) Firestore save in the background with an 8s timeout guard
        let incomeVal = income
        let expensesVal = expenses
        let budgetVal = budget

        Task.detached {
            do {
                try await withTimeout(seconds: 8) {
                    try await UserService.shared.updateFinancials(
                        uid: uid,
                        income: incomeVal,
                        expenses: expensesVal,
                        budget: budgetVal
                    )
                }
            } catch {
                // Log; don't block user flow.
                print("Background save failed or timed out: \(error)")
            }
        }

        // 3) Stop the spinner quickly (we’re already navigating)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
        }
    }

    // MARK: - Timeout helper
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError.timedOut       // ✅ use the file‑scope enum
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - UI helpers
    @ViewBuilder
    private func currencyField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .padding(.top, 2)
    }

    @ViewBuilder
    private func summaryRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(formatCurrency(value))
                .fontWeight(.semibold)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        // f.currencyCode = "LKR" // uncomment to force LKR
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// Theme‑matching card
fileprivate struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 7, x: 0, y: 2)
    }
}
