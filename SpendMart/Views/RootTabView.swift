import SwiftUI

/// Root tab bar for the whole app.
struct RootTabView: View {
    init() {
        // Make tab bar translucent with custom background
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { CategoriesView() }
                .tabItem { Label("Categories", systemImage: "square.grid.2x2") }

            NavigationStack { ScanView() }
                .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }

            NavigationStack { DueView() }
                .tabItem { Label("Due", systemImage: "calendar.badge.exclamationmark") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "person") }
        }
        .tint(.blue) // Accent color for icons
    }
}




