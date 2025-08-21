// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Categories")
                }
                .tag(1)
            
            ScanView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "camera.fill" : "camera")
                    Text("Scan")
                }
                .tag(2)
            
            DueView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "doc.text.fill" : "doc.text")
                    Text("Due")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}
