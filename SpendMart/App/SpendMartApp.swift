//import SwiftUI
//import FirebaseCore
//
//@main
//struct SpendMartApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var session = SessionViewModel()
//    
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environmentObject(session)
//                .onAppear {
//                    print("Firebase configured? \(FirebaseApp.app() != nil)")
//                }
//        }
//    }
//}


import SwiftUI
import FirebaseCore

@main
struct SpendMartApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appSession = AppSession()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appSession)
                .onAppear {
                    print("Firebase configured? \(FirebaseApp.app() != nil)")
                }
        }
    }
}
