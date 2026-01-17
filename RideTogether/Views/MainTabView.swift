//
//  MainTabView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1
    @StateObject private var groupViewModel = GroupBadgeViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            JourneyView()
                .tabItem {
                    Label("地圖", systemImage: selectedTab == 0 ? "map.fill" : "map")
                }
                .tag(0)
            
            HomeView()
                .tabItem {
                    Label("探索", systemImage: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                }
                .tag(1)
            
            GroupView()
                .tabItem {
                    Label("群組", systemImage: selectedTab == 2 ? "rectangle.3.group.bubble.left.fill" : "rectangle.3.group.bubble.left")
                }
                .badge(groupViewModel.badgeCount > 0 ? "\(groupViewModel.badgeCount)" : nil)
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("個人", systemImage: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                }
                .tag(3)
        }
        .onAppear {
            setupTabBarAppearance()
            groupViewModel.startListening()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Group Badge ViewModel

class GroupBadgeViewModel: ObservableObject {
    @Published var badgeCount = 0
    
    func startListening() {
        GroupManager.shared.addRequestListener { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let requests):
                    let userInfo = UserManager.shared.userInfo
                    let filteredRequests = requests.filter { request in
                        !(userInfo.blockList?.contains(request.requestId) ?? false)
                    }
                    self?.badgeCount = filteredRequests.count
                case .failure:
                    self?.badgeCount = 0
                }
            }
        }
    }
}

