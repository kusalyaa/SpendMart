import SwiftUI
import Combine
import UIKit

struct BiometricGateView: View {
    var onUnlocked: () -> Void

    @State private var isPrompting = false
    @State private var lastFailed = false
    @State private var fgObserver: AnyCancellable?

    private func log(_ msg: String, file: StaticString = #fileID, line: Int = #line) {
        print("[Flow][BiometricGateView] \(msg)  (\(file):\(line))")
    }

    private var title: String {
        switch BiometricAuth.available() {
        case .faceID:  return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        case .none:    return "Unlock"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(.blue)
                .padding(.bottom, 8)

            Text("SpendSmart is Locked")
                .font(.title3).fontWeight(.semibold)

            if lastFailed {
                Text("Authentication failed. Try again.")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            Button {
                log("Unlock button tapped → prompt()")
                prompt()
            } label: {
                HStack {
                    if isPrompting { ProgressView().tint(.white) }
                    Text(isPrompting ? "Authenticating..." : title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            }
            .disabled(isPrompting)

            Spacer()
            Text("Face ID/Passcode protects your financial data.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .onAppear {
            log("onAppear — isPrompting=\(isPrompting), lastFailed=\(lastFailed)")
            startForegroundObserver()
            prompt() // auto-prompt on open
        }
        .onDisappear {
            log("onDisappear — removing foreground observer")
            fgObserver?.cancel()
            fgObserver = nil
        }
    }

    // MARK: - Helpers

    private func startForegroundObserver() {
        guard fgObserver == nil else { return }
        fgObserver = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                // auto-prompt when returning to foreground if still locked
                if !isPrompting {
                    log("didBecomeActive → auto prompt()")
                    prompt()
                } else {
                    log("didBecomeActive → already prompting; skip")
                }
            }
        log("Foreground observer installed")
    }

    private func prompt() {
        // Guard against double triggers
        if isPrompting {
            log("prompt() called while already prompting → ignore")
            return
        }

        isPrompting = true
        lastFailed = false

        let availability: String
        switch BiometricAuth.available() {
        case .faceID:  availability = "faceID"
        case .touchID: availability = "touchID"
        case .none:    availability = "none"
        }
        log("prompt() start — availability=\(availability)")

        BiometricAuth.authenticate(allowPasscode: false, reason: "Unlock SpendMart") { success in
            if success {
                log("biometrics-only evaluatePolicy → success → onUnlocked()")
                isPrompting = false
                onUnlocked()
            } else {
                log("biometrics-only evaluatePolicy → failed → try fallback with passcode")
                // Optional second attempt with passcode fallback:
                BiometricAuth.authenticate(allowPasscode: true, reason: "Unlock SpendMart") { second in
                    isPrompting = false
                    if second {
                        log("fallback (with passcode) → success → onUnlocked()")
                        onUnlocked()
                    } else {
                        lastFailed = true
                        log("fallback (with passcode) → failed → remain locked (lastFailed=true)")
                    }
                }
            }
        }
    }
}
