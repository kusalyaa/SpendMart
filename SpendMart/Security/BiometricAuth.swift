import LocalAuthentication

enum BiometryKind { case none, touchID, faceID }

enum BiometricAuth {
    static func available() -> BiometryKind {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) {
            switch ctx.biometryType {
            case .faceID:  return .faceID
            case .touchID: return .touchID
            default:       return .none
            }
        }
        return .none
    }

    static func authenticate(
        reason: String = "Unlock SpendSmart",
        allowPasscode: Bool = true,
        completion: @escaping (Bool) -> Void
    ) {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = allowPasscode ? "Use Passcode" : ""

        var error: NSError?
        // Prefer passcode + biometrics. If not available, try biometrics-only. Otherwise fail.
        var policy: LAPolicy = allowPasscode ? .deviceOwnerAuthentication
                                             : .deviceOwnerAuthenticationWithBiometrics

        if !ctx.canEvaluatePolicy(policy, error: &error) {
            if allowPasscode,
               ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                policy = .deviceOwnerAuthenticationWithBiometrics
            } else {
                DispatchQueue.main.async { completion(false) }
                return
            }
        }

        ctx.evaluatePolicy(policy, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
