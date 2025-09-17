import LocalAuthentication

enum BiometryKind { case none, touchID, faceID }

enum BiometricAuth {

    /// Use the biometrics policy to get a correct biometryType.
    static func available() -> BiometryKind {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            switch ctx.biometryType {
            case .faceID:  return .faceID
            case .touchID: return .touchID
            default:       return .none
            }
        }
        return .none
    }

    /// First try *only* biometrics. Passcode fallback is opt-in via `allowPasscode`.
    static func authenticate(
        allowPasscode: Bool = false,
        reason: String = "Unlock SpendMart",
        completion: @escaping (Bool) -> Void
    ) {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"
        // Hide "Enter Password" on the first prompt if we don't want fallback yet
        if !allowPasscode { ctx.localizedFallbackTitle = "" }

        var error: NSError?
        let policy: LAPolicy = allowPasscode
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics

        guard ctx.canEvaluatePolicy(policy, error: &error) else {
            DispatchQueue.main.async { completion(false) }
            return
        }

        ctx.evaluatePolicy(policy, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
