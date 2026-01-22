//
//  AuthStateManager.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import FirebaseAuth
import Combine

internal class AuthStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userInfo: UserInfo?
    @Published var isLoading = true

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let userRepository: UserRepositoryProtocol

    // MARK: - Init
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
        setupAuthListener()
    }

    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserInfo(uid: user.uid)
            } else {
                // User logged out - update state on main thread via Combine
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                    self?.userInfo = nil
                    self?.isLoading = false

                    // Clear UserManager state (backward compatibility)
                    UserManager.shared.userInfo = UserInfo()
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

        // Use UserRepository with Combine instead of callbacks
        userRepository.fetchUserInfo(uid: uid)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to fetch user info: \(error.localizedDescription)")
                        self?.isAuthenticated = false
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] userInfo in
                    // CRITICAL: Single source of truth - only update AuthStateManager.userInfo
                    // Update UserManager for backward compatibility with existing code
                    UserManager.shared.userInfo = userInfo

                    self?.userInfo = userInfo
                    self?.isAuthenticated = true
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        cancellables.removeAll()
    }
}

