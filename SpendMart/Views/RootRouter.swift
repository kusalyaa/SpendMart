// SpendMart/SpendMart/Views/RootRouter.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RootRouter: View {
    @EnvironmentObject var session: SessionViewModel
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        Group {
            // 1) No user yet → show your LoginView (or onboarding that leads to login)
            if session.firebaseUser == nil {
                NavigationStack { LoginView() } // <- change if your entry is different
            }
            // 2) User present but not verified → Confirm Email every login
            else if !session.isEmailVerified {
                ConfirmEmailWatcher()
            }
            // 3) Verified user → Gate on Income Setup once
            else if let uid = session.firebaseUser?.uid {
                RoutedMain(uid: uid)
            }
        }
        .onChange(of: session.firebaseUser?.uid) { _, newUid in
            if let uid = newUid { userStore.bind(uid: uid) }
        }
    }
}

private struct RoutedMain: View {
    let uid: String
    @EnvironmentObject var userStore: UserStore

    var needsIncomeSetup: Bool {
        !(userStore.userDoc?.flags?.hasCompletedIncomeSetup ?? false)
    }

    var body: some View {
        if needsIncomeSetup {
            IncomeSetupGate(uid: uid)
        } else {
            // ✅ Replace with your tab root if different:
            DashboardView()
        }
    }
}

/// Wraps your existing ConfirmEmailView and watches verification status.
/// No need to modify your ConfirmEmailView file.
private struct ConfirmEmailWatcher: View {
    @EnvironmentObject var session: SessionViewModel
    @State private var timerOn = true

    var body: some View {
        ZStack {
            ConfirmEmailView() // your existing UI
                .onAppear { timerOn = true }
                .onDisappear { timerOn = false }

            // (Optional) tiny overlay to refresh manually if needed
            VStack {
                Spacer()
                Button("I’ve verified — Refresh") {
                    Task { await session.refreshVerification() }
                }
                .padding(.bottom, 24)
            }
        }
        .task(id: timerOn) {
            // Poll every 3s; once verified the router will advance automatically
            while timerOn && !(session.isEmailVerified) {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await session.refreshVerification()
            }
        }
    }
}

/// Shows your IncomeSetupView until we detect income is saved, then flips the flag.
/// No need to modify your IncomeSetupView file.
private struct IncomeSetupGate: View {
    let uid: String
    @EnvironmentObject var userStore: UserStore
    @State private var listenerAttached = false

    var body: some View {
        IncomeSetupView() // your existing UI
            .onAppear {
                attachAutoCompleteListenerIfNeeded()
            }
    }

    private func attachAutoCompleteListenerIfNeeded() {
        guard !listenerAttached else { return }
        listenerAttached = true

        let ref = Firestore.firestore().collection("users").document(uid)
        ref.addSnapshotListener { [weak userStore] snap, _ in
            guard let data = snap?.data() else { return }

            // Heuristics: mark as complete when income is saved.
            // Works with documents shaped like:
            // { income: { monthly: <num>, autoBudget: <bool> } }  OR  { monthlyIncome: <num> }
            let incomeFromNested = (data["income"] as? [String: Any])?["monthly"] as? NSNumber
            let incomeFlat = data["monthlyIncome"] as? NSNumber

            let hasIncome = ((incomeFromNested?.doubleValue ?? 0) > 0) || ((incomeFlat?.doubleValue ?? 0) > 0)
            if hasIncome {
                userStore?.markIncomeSetupDone(uid: uid)
            }
        }
    }
}
