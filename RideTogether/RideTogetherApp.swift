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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Create repository container first
    @StateObject private var repositories = RepositoryContainer.live()

    // Create AuthStateManager with UserRepository from container
    @StateObject private var authState: AuthStateManager

    init() {
        setupFirebase()

        // Initialize AuthStateManager with repository
        let container = RepositoryContainer.live()
        _authState = StateObject(wrappedValue: AuthStateManager(userRepository: container.userRepository))
        _repositories = StateObject(wrappedValue: container)
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

