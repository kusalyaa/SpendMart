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

private func lkr(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "LKR"
    f.maximumFractionDigits = (v.rounded() == v) ? 0 : 2
    return f.string(from: NSNumber(value: v)) ?? "LKR \(Int(v))"
}

// MARK: - Settings Screen

struct SettingsView: View {
    @StateObject private var vm = SettingsVM()
    @State private var goProfile = false
    @State private var goEmergency = false
    @State private var goDocuments = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Profile Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                avatarCircle(text: initials(from: vm.displayName))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.displayName.isEmpty ? "Your Name" : vm.displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text(vm.email.isEmpty ? "you@email.com" : vm.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button { goProfile = true } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.blue)
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)

                        // Financial Overview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Financial Overview")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                statTile(title: "Monthly Income", value: vm.monthlyIncome, color: .green)
                                statTile(title: "Monthly Expenses", value: vm.monthlyExpenses, color: .red)
                                statTile(title: "Monthly Budget", value: vm.monthlyBudget, color: .blue)
                                statTile(title: "Budget Spent", value: vm.budgetSpent, color: .orange)
                                statTile(title: "Emergency Fund", value: vm.emergencyFund, color: .purple)
                                statTile(title: "Free Cash", value: vm.freeCash, color: .cyan)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)

                        // Management Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Manage")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                managementRow(
                                    icon: "shield.lefthalf.filled",
                                    title: "Emergency Fund",
                                    subtitle: "Add from Free Cash (one-time)",
                                    value: lkr(vm.emergencyFund),
                                    color: .purple
                                ) { goEmergency = true }
                                
                                Divider()
                                    .padding(.horizontal, 12)
                                
                                managementRow(
                                    icon: "doc.richtext",
                                    title: "Documents",
                                    subtitle: "NIC/ID, Utility, Statement",
                                    value: "Manage",
                                    color: .blue
                                ) { goDocuments = true }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
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

    // MARK: - UI Components

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "U"
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private func avatarCircle(text: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 60, height: 60)
    }

    private func statTile(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(lkr(value))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }

    private func managementRow(
        icon: String,
        title: String,
        subtitle: String,
        value: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
