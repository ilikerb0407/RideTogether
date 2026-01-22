//
//  MainTabView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @State private var selectedTab = 1
    @Environment(\.repositories) private var repositories
    @StateObject private var groupBadgeViewModel: GroupBadgeViewModel

    init() {
        // Initialize with placeholder repository
        let placeholderRepo = GroupRepository()
        _groupBadgeViewModel = StateObject(wrappedValue: GroupBadgeViewModel(repository: placeholderRepo))
    }

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
                .badge(groupBadgeViewModel.badgeCount > 0 ? "\(groupBadgeViewModel.badgeCount)" : nil)
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("個人", systemImage: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                }
                .tag(3)
        }
        .onAppear {
            setupTabBarAppearance()
            groupBadgeViewModel.startListening()
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

/// ViewModel for managing group request badge count
/// CRITICAL FIX: Uses Combine + GroupRepository to properly manage Firestore listeners
/// This replaces the memory leak-prone GroupManager.addRequestListener
class GroupBadgeViewModel: ObservableObject {
    @Published var badgeCount = 0

    // MARK: - Dependencies
    private let repository: GroupRepositoryProtocol

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }

    /// Start listening to requests and update badge count
    /// Uses Combine's observeRequests() which properly manages the Firestore listener
    func startListening() {
        repository.observeRequests()
            .map { requests in
                // Filter out blocked users
                let userInfo = UserManager.shared.userInfo
                let blockList = userInfo.blockList ?? []
                return requests.filter { request in
                    !blockList.contains(request.requestId)
                }.count
            }
            .replaceError(with: 0) // If error occurs, show 0 badge
            .assign(to: &$badgeCount) // Automatically updates on main thread via repository
    }

    // MARK: - Deinit
    deinit {
        // Cancellables automatically cleaned up - this prevents memory leak
        cancellables.removeAll()
    }
}

