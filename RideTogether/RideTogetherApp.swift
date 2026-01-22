//
//  RideTogetherApp.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct RideTogetherApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Create repository container and auth state manager
    @StateObject private var repositories: RepositoryContainer = .init()
    @StateObject private var authState: AuthStateManager = .init()

    init() {
        // Setup Firebase FIRST
        setupFirebase()

        // Initialize repositories and auth state manager
        let container = RepositoryContainer.live()
        _repositories = StateObject(wrappedValue: container)
        _authState = StateObject(wrappedValue: AuthStateManager(userRepository: container.userRepository))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
                .environmentObject(repositories)
                .onAppear {
                    authState.checkAuthState()
                }
        }
    }

    private func setupFirebase() {
        FirebaseApp.configure()
    }
}
