//
//  AuthStateManager.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import FirebaseAuth

internal class AuthStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userInfo: UserInfo?
    @Published var isLoading = true
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserInfo(uid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.userInfo = nil
                    self?.isLoading = false
                }
            }
        }
    }
    
    func checkAuthState() {
        if let currentUser = Auth.auth().currentUser {
            fetchUserInfo(uid: currentUser.uid)
        } else {
            isAuthenticated = false
            isLoading = false
        }
    }
    
    private func fetchUserInfo(uid: String) {
        isLoading = true
        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    UserManager.shared.userInfo = userInfo
                    self?.userInfo = userInfo
                    self?.isAuthenticated = true
                case .failure(let error):
                    print("Failed to fetch user info: \(error)")
                    self?.isAuthenticated = false
                }
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

