import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - ViewModel

final class SettingsVM: ObservableObject {
    // Profile
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var address: String = ""

    // Financials
    @Published var monthlyBudget: Double = 0
    @Published var budgetSpent: Double = 0
    @Published var emergencyFund: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpenses: Double = 0
    @Published var netAfterExpenses: Double = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Free cash = income − expenses − budget − EF (never below 0)
    var freeCash: Double {
        max((monthlyIncome - monthlyExpenses) - monthlyBudget - emergencyFund, 0)
    }

    func listen() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snap, _ in
            guard let self, let data = snap?.data() else { return }

            // Robust profile read: support both old flat keys and new nested 'profile'
            let p = data["profile"] as? [String: Any]
            self.displayName = (p?["name"] as? String)
                            ?? (data["name"] as? String)
                            ?? self.displayName
            self.phone       = (p?["phone"] as? String)
                            ?? (data["phone"] as? String)
                            ?? self.phone
            self.address     = (p?["address"] as? String)
                            ?? (data["address"] as? String)
                            ?? self.address
            // Email from auth (fallback to stored field if you keep one)
            self.email = Auth.auth().currentUser?.email
                      ?? (data["email"] as? String)
                      ?? self.email

            // Financials
            let f = data["financials"] as? [String: Any] ?? [:]
            self.monthlyBudget   = f["monthlyBudget"] as? Double ?? 0
            self.budgetSpent     = f["budgetSpent"] as? Double ?? 0
            self.emergencyFund   = f["emergencyFund"] as? Double ?? 0
            self.monthlyIncome   = f["monthlyIncome"] as? Double ?? 0
            self.monthlyExpenses = f["monthlyExpenses"] as? Double ?? 0
            self.netAfterExpenses = f["netAfterExpenses"] as? Double
                ?? ((self.monthlyIncome - self.monthlyExpenses) - self.budgetSpent)
        }
    }

    deinit { listener?.remove() }
}

// MARK: - Settings Screen

struct SettingsView: View {
    @StateObject private var vm = SettingsVM()
    @State private var goProfile = false
    @State private var goEmergency = false
    @State private var goDocuments = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Profile card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            avatarCircle(text: initials(from: vm.displayName))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.displayName.isEmpty ? "Your Name" : vm.displayName)
                                    .font(.headline)
                                Text(vm.email.isEmpty ? "you@email.com" : vm.email)
                                    .font(.caption)
                                    .foregroundColor(.appSecondaryTxt)
                            }
                            Spacer()
                            Button { goProfile = true } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.appBrand)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)

                    // Overview metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview").font(.headline)
                        gridRow {
                            statTile(title: "Monthly Income", value: vm.monthlyIncome)
                            statTile(title: "Monthly Expenses", value: vm.monthlyExpenses)
                        }
                        gridRow {
                            statTile(title: "Monthly Budget", value: vm.monthlyBudget)
                            statTile(title: "Spent (this month)", value: vm.budgetSpent)
                        }
                        gridRow {
                            statTile(title: "Emergency Fund", value: vm.emergencyFund)
                            statTile(title: "Free Cash", value: vm.freeCash)
                        }
                        gridRow {
                            statTile(title: "Net After Exp.", value: vm.netAfterExpenses)
                            statTile(title: "Income − Exp.", value: vm.monthlyIncome - vm.monthlyExpenses)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)

                    // Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manage").font(.headline).padding(.horizontal, 2)

                        VStack(spacing: 0) {
                            settingsRow(
                                icon: "shield.lefthalf.filled",
                                title: "Emergency Fund",
                                subtitle: "Add from Free Cash (one-time)",
                                value: String(format: "LKR %.0f", vm.emergencyFund)
                            ) { goEmergency = true }
                            Divider()
                            settingsRow(
                                icon: "doc.richtext",
                                title: "Documents",
                                subtitle: "NIC/ID, Utility, Statement",
                                value: "Add / View"
                            ) { goDocuments = true }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            // ✅ Big, left-aligned title like other screens
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { vm.listen() }
            .navigationDestination(isPresented: $goProfile) {
                EditProfileView(currentName: vm.displayName, currentPhone: vm.phone, currentAddress: vm.address)
            }
            .navigationDestination(isPresented: $goEmergency) {
                ManageEmergencyFundView()
            }
            .navigationDestination(isPresented: $goDocuments) {
                ManageDocumentsView()
            }
        }
        .tint(Color.appBrand)
    }

    // MARK: - Small UI helpers

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "U"
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private func avatarCircle(text: String) -> some View {
        ZStack {
            Circle().fill(Color.appBrand.opacity(0.12))
            Text(text).font(.headline).foregroundColor(Color.appBrand)
        }
        .frame(width: 48, height: 48)
    }

    private func gridRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) { content() }
    }

    private func statTile(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.appSecondaryTxt)
            Text(String(format: "LKR %.0f", value)).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(
                LinearGradient(colors: [Color.appBrand.opacity(0.08), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        )
    }

    @ViewBuilder
    private func settingsRow(icon: String, title: String, subtitle: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.appBrand.opacity(0.12))
                    Image(systemName: icon).foregroundColor(Color.appBrand)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body)
                    Text(subtitle).font(.caption).foregroundColor(.appSecondaryTxt)
                }
                Spacer()
                Text(value).font(.subheadline).foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}
