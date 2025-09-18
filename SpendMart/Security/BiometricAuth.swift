import LocalAuthentication

enum BiometryKind { case none, touchID, faceID }

enum BiometricAuth {

    static func available() -> BiometryKind {
        let ctx = LAContext()
        var err: NSError?
        let canBio = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        let typeStr: String
        let kind: BiometryKind
        if canBio {
            switch ctx.biometryType {
            case .faceID:  typeStr = "faceID";  kind = .faceID
            case .touchID: typeStr = "touchID"; kind = .touchID
            default:       typeStr = "none";    kind = .none
            }
        } else {
            typeStr = "none"
            kind = .none
        }
        print("[Flow][BiometricAuth] available() → \(typeStr) | canEvaluate=\(canBio) | err=\(String(describing: err?.localizedDescription))")
        return kind
    }

    static func authenticate(
        allowPasscode: Bool = false,
        reason: String = "Unlock SpendMart",
        completion: @escaping (Bool) -> Void
    ) {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"
        if !allowPasscode { ctx.localizedFallbackTitle = "" }

        let policy: LAPolicy = allowPasscode ? .deviceOwnerAuthentication
                                             : .deviceOwnerAuthenticationWithBiometrics

        var error: NSError?
        let canEval = ctx.canEvaluatePolicy(policy, error: &error)
        print("[Flow][BiometricAuth] authenticate(allowPasscode=\(allowPasscode)) | policy=\(policy == .deviceOwnerAuthentication ? "deviceOwnerAuth" : "biometricsOnly") | canEvaluate=\(canEval) | err=\(String(describing: error?.localizedDescription))")

        guard canEval else {
            DispatchQueue.main.async { completion(false) }
            return
        }

        ctx.evaluatePolicy(policy, localizedReason: reason) { success, evalError in
            print("[Flow][BiometricAuth] evaluatePolicy → success=\(success) | err=\(String(describing: evalError?.localizedDescription))")
            DispatchQueue.main.async { completion(success) }
        }
    }
}
