import Foundation
import FirebaseAuth
import FirebaseFirestore
import AVFoundation
import UserNotifications

@MainActor
final class SettingsStore: ObservableObject {
    
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var occupation: String = ""
    @Published var incomeLKR: String = ""
    @Published var address: String = ""

    
    @Published var cameraAllowed: Bool = false
    @Published var notificationsAllowed: Bool = false

    private var sub: ListenerRegistration?

    func bind() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("users").document(uid)

        sub?.remove()
        sub = ref.addSnapshotListener { [weak self] snap, _ in
            guard let self = self, let data = snap?.data() else { return }

            self.name       = (data["displayName"] as? String) ?? ""
            self.email      = (data["email"] as? String) ?? Auth.auth().currentUser?.email ?? ""
            self.phone      = (data["phone"] as? String) ?? ""
            self.occupation = (data["occupation"] as? String) ?? ""
            self.address    = (data["address"] as? String) ?? ""

            if let fin = data["financials"] as? [String: Any] {
                let income = Self.double(fin["monthlyIncome"])
                self.incomeLKR = Self.lkr(income)
            } else {
                self.incomeLKR = Self.lkr(0)
            }
        }

        refreshPermissions()
    }

    deinit { sub?.remove() }

    func refreshPermissions() {
        
        let cam = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAllowed = (cam == .authorized)

        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }

    func toggleCamera(_ desired: Bool) {
        if desired {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async { self.refreshPermissions() }
            }
        } else {
            openAppSettings() 
        }
    }

    func toggleNotifications(_ desired: Bool) {
        if desired {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async { self.refreshPermissions() }
            }
        } else {
            openAppSettings()
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: helpers
    private static func double(_ any: Any?) -> Double {
        switch any {
        case let x as Double: return x
        case let x as Int: return Double(x)
        case let x as NSNumber: return x.doubleValue
        case let s as String: return Double(s) ?? 0
        default: return 0
        }
    }

    private static func lkr(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "LKR"
        f.maximumFractionDigits = (v.rounded() == v) ? 0 : 2
        return f.string(from: NSNumber(value: v)) ?? "LKR \(Int(v))"
    }
}
