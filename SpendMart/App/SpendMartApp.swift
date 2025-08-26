import SwiftUI
import FirebaseCore

@main
struct SpendMartApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = SessionViewModel()   

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .onAppear {
                    print("Firebase configured? \(FirebaseApp.app() != nil)")
                }
        }
    }
}
// SpendMart/SpendMart/App/SpendMartApp.swift
//import SwiftUI
//import FirebaseCore
//
//@main
//struct SpendMartApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var session = SessionViewModel()
//    @StateObject private var userStore = UserStore()
//
//    var body: some Scene {
//        WindowGroup {
//            RootRouter()
//                .environmentObject(session)
//                .environmentObject(userStore)
//        }
//    }
//}
