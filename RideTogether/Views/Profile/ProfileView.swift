//
//  ProfileView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var userInfo = UserManager.shared.userInfo
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    ProfileHeaderView(userInfo: userInfo)
                } header: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Menu Items
                ForEach(ProfileItemType.allCases, id: \.self) { item in
                    Section {
                        ProfileMenuItem(item: item)
                    } header: {
                        EmptyView()
                    }
                }
            }
            .listStyle(.grouped)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.B3],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.85)
            )
            .navigationTitle("個人")
        }
    }
}

struct ProfileHeaderView: View {
    let userInfo: UserInfo
    
    var body: some View {
        VStack {
            // Profile photo and name
            Text("Profile Header")
        }
        .frame(height: 294)
    }
}

struct ProfileMenuItem: View {
    let item: ProfileItemType
    @State private var showAccountSettings = false
    
    var body: some View {
        Button(action: {
            handleItemTap()
        }) {
            HStack {
                if let image = item.image {
                    Image(uiImage: image)
                        .foregroundColor(Color.B5)
                }
                Text(item.title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(height: 60)
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView()
        }
    }
    
    private func handleItemTap() {
        switch item {
        case .routeRecord:
            // Navigate to TracksViewController
            break
        case .recommendMap:
            // Navigate to RecommendViewController
            break
        case .userAccount:
            showAccountSettings = true
        case .saveRoutes:
            // Navigate to SaveMapsViewController
            break
        }
    }
}

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authState: AuthStateManager
    
    var body: some View {
        NavigationView {
            List {
                Button("登出帳號") {
                    signOut()
                }
                .foregroundColor(.blue)
                
                Button("刪除帳號") {
                    deleteAccount()
                }
                .foregroundColor(.red)
            }
            .navigationTitle("帳戶設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            authState.isAuthenticated = false
            dismiss()
        } catch {
            print("Sign out error: \(error)")
        }
    }
    
    private func deleteAccount() {
        // Implementation
    }
}

