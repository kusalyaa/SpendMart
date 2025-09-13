import SwiftUI
import FirebaseAuth

// Brand + secondary text colors
fileprivate extension Color {
    static let brand = Color.blue // iOS system blue
    static let secondaryText = Color(hex: "8790A5")

    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0; Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8)  / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var store = SettingsStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Title (brand color) - Enhanced with better spacing
                    HStack {
                        Spacer()
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brand)
                        Spacer()
                    }
                    .padding(.top, 12)

                    // Header (name brand; email secondaryText) - Enhanced with better visual hierarchy
                    ProfileHeader(
                        name: store.name.isEmpty ? "Your Name" : store.name,
                        email: store.email.isEmpty ? (Auth.auth().currentUser?.email ?? "") : store.email
                    )

                    // Personal Info - Enhanced card design
                    SectionHeader("Personal Information")
                    Card {
                        VStack(spacing: 0) {
                            SettingsValueRow(label: "Name", value: store.name)
                            Divider().opacity(0.3).padding(.vertical, 12)
                            SettingsValueRow(label: "Email", value: store.email)
                            Divider().opacity(0.3).padding(.vertical, 12)
                            SettingsValueRow(label: "Contact Number", value: store.phone)
                            Divider().opacity(0.3).padding(.vertical, 12)
                            SettingsValueRow(label: "Occupation", value: store.occupation)
                            Divider().opacity(0.3).padding(.vertical, 12)
                            SettingsValueRow(label: "Income", value: store.incomeLKR)
                            Divider().opacity(0.3).padding(.vertical, 12)
                            SettingsValueRow(label: "Address", value: store.address)
                        }
                    }

                    // Add Funds - Enhanced with icons and better spacing
                    SectionHeader("Add Funds")
                    Card(spacing: 0) {
                        VStack(spacing: 0) {
                            NavRow(title: "Add Emergency Fund", icon: "shield.fill") { }
                            Divider().opacity(0.2).padding(.vertical, 16)
                            NavRow(title: "Add Fund", icon: "plus.circle.fill") { }
                        }
                    }

                    // Documents - Enhanced with relevant icons
                    SectionHeader("Documents")
                    Card(spacing: 0) {
                        VStack(spacing: 0) {
                            NavRow(title: "NIC / ID Card", icon: "person.text.rectangle.fill") { }
                            Divider().opacity(0.2).padding(.vertical, 16)
                            NavRow(title: "Salary Slip", icon: "doc.text.fill") { }
                            Divider().opacity(0.2).padding(.vertical, 16)
                            NavRow(title: "Account Statement", icon: "chart.line.uptrend.xyaxis") { }
                        }
                    }

                    // Permissions - Enhanced toggle design
                    SectionHeader("Permissions")
                    Card(spacing: 0) {
                        VStack(spacing: 0) {
                            PermissionToggleRow(title: "Camera", icon: "camera.fill",
                                                isOn: store.cameraAllowed,
                                                onToggle: { store.toggleCamera($0) })
                            Divider().opacity(0.2).padding(.vertical, 16)
                            PermissionToggleRow(title: "Notifications", icon: "bell.fill",
                                                isOn: store.notificationsAllowed,
                                                onToggle: { store.toggleNotifications($0) })
                        }
                    }

                    // Logout - Enhanced button design
                    Button(role: .destructive, action: signOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                            Text("Log Out")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                    }
                    .background(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(14)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear { store.bind() }
    }

    private func signOut() {
        do { try Auth.auth().signOut() } catch { print("Sign out error: \(error)") }
    }
}

// MARK: - Components

fileprivate struct ProfileHeader: View {
    var name: String
    var email: String
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.brand.opacity(0.3), lineWidth: 2)
                    )
                Image(systemName: "person.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Color.brand)
            }
            VStack(spacing: 6) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brand)
                Text(email.isEmpty ? "—" : email)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

fileprivate struct SectionHeader: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack {
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.brand)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

fileprivate struct Card<Content: View>: View {
    var spacing: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content() }
            .padding(18)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

// Labels = secondaryText; values = brand - Enhanced with better spacing
fileprivate struct SettingsValueRow: View {
    var label: String
    var value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(Color.secondaryText)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer(minLength: 20)
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(Color.brand)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// Enhanced with icons and better styling
fileprivate struct NavRow: View {
    var title: String
    var icon: String = ""
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.brand)
                        .frame(width: 20, height: 20)
                }
                Text(title)
                    .foregroundStyle(Color.secondaryText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondaryText.opacity(0.6))
            }
            .padding(.vertical, 2)
        }
        .contentShape(Rectangle())
    }
}

// Enhanced with icons and better toggle styling
fileprivate struct PermissionToggleRow: View {
    var title: String
    var icon: String = ""
    var isOn: Bool
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.brand)
                    .frame(width: 20, height: 20)
            }
            Text(title)
                .foregroundStyle(Color.secondaryText)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Toggle("",
                   isOn: Binding(
                       get: { isOn },
                       set: { onToggle($0) }
                   )
            )
            .tint(Color.brand)
            .labelsHidden()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
