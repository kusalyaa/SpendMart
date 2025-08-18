// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(spacing: 4) {
                            Text("John Abraham")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text("johnabraham@student.campus.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top)
                    
                    // Personal Information
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Personal Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        SettingsRow(label: "Name", value: "John Abraham")
                        SettingsRow(label: "Email", value: "johnabraham@student.campus.com")
                        SettingsRow(label: "Contact Number", value: "+94 77 211 5701")
                        SettingsRow(label: "Occupation", value: "Developer")
                        SettingsRow(label: "Income", value: "johnabraham@student.campus.com")
                        SettingsRow(label: "Address", value: "2A cascia Ave Ratmalana")
                    }
                    .padding(.horizontal)
                    
                    // Add Funds Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Add Funds")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        SettingsActionRow(icon: "plus.circle", title: "Add Emergency Fund")
                        SettingsActionRow(icon: "plus.circle", title: "Add Fund")
                    }
                    .padding(.horizontal)
                    
                    // Documents Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Documents")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        SettingsActionRow(icon: "doc.fill", title: "NIC/ID Card")
                        SettingsActionRow(icon: "doc.fill", title: "Salary Slip")
                        SettingsActionRow(icon: "doc.fill", title: "Account Statement")
                    }
                    .padding(.horizontal)
                    
                    // Permissions Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Permissions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        PermissionRow(icon: "camera.fill", title: "Camera", isEnabled: true)
                        PermissionRow(icon: "bell.fill", title: "Notifications", isEnabled: true)
                    }
                    .padding(.horizontal)
                    
                    // Log Out Button
                    Button(action: {}) {
                        Text("Log Out")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
