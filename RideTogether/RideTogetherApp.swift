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
    @StateObject private var authState = AuthStateManager()
    
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
                .onAppear {
                    authState.checkAuthState()
                }
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
}

