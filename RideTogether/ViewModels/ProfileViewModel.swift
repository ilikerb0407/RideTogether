//
//  ProfileViewModel.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

/// ViewModel for Profile feature following MVVM + Combine architecture
/// Manages user profile, records, and account settings
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    // User data
    @Published var userInfo: UserInfo?
    @Published var records: [Record] = []

    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showEditProfile = false
    @Published var showImagePicker = false

    // Edit profile state
    @Published var editedUserName = ""
    @Published var selectedImage: UIImage?

    // Stats
    @Published var totalDistance: Double = 0
    @Published var totalRecordings: Int = 0

    // MARK: - Dependencies
    private let userRepository: UserRepositoryProtocol
    private let recordRepository: RecordRepositoryProtocol
    private let authStateManager: AuthStateManager

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init (Dependency Injection)
    init(
        userRepository: UserRepositoryProtocol,
        recordRepository: RecordRepositoryProtocol,
        authStateManager: AuthStateManager
    ) {
        self.userRepository = userRepository
        self.recordRepository = recordRepository
        self.authStateManager = authStateManager

        setupUserObserver()
    }

    // MARK: - Public Methods

    /// Fetch user records
    func fetchRecords() {
        guard let userId = userInfo?.uid, !userId.isEmpty else {
            return
        }

        isLoading = true
        errorMessage = nil

        recordRepository.fetchRecords(forUserId: userId)
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] records in
                    self?.records = records
                    self?.totalRecordings = records.count
                    // Calculate total distance if available from records metadata
                }
            )
            .store(in: &cancellables)
    }

    /// Update user name
    func updateUserName(_ newName: String) {
        guard !newName.isEmpty else {
            errorMessage = "名稱不能為空"
            return
        }

        isLoading = true
        errorMessage = nil

        userRepository.updateUserName(newName)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "更新名稱失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] in
                    self?.errorMessage = "名稱更新成功"
                    self?.showEditProfile = false
                    // Update local userInfo
                    self?.userInfo?.userName = newName
                }
            )
            .store(in: &cancellables)
    }

    /// Upload profile picture
    func uploadProfilePicture(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            errorMessage = "圖片處理失敗"
            return
        }

        isLoading = true
        errorMessage = nil

        userRepository.uploadUserPicture(imageData)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "上傳圖片失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] url in
                    self?.errorMessage = "圖片上傳成功"
                    self?.selectedImage = nil
                    // Update local userInfo
                    self?.userInfo?.pictureRef = url.absoluteString
                }
            )
            .store(in: &cancellables)
    }

    /// Delete a record
    func deleteRecord(_ record: Record) {
        isLoading = true
        errorMessage = nil

        recordRepository.deleteRecord(fileName: record.recordName)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "刪除失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] in
                    self?.errorMessage = "刪除成功"
                    // Refresh records
                    self?.fetchRecords()
                }
            )
            .store(in: &cancellables)
    }

    /// Sign out user
    func signOut() {
        do {
            try Auth.auth().signOut()
            authStateManager.isAuthenticated = false
            authStateManager.userInfo = nil
            UserManager.shared.userInfo = UserInfo() // Clear shared state
        } catch {
            errorMessage = "登出失敗: \(error.localizedDescription)"
        }
    }

    /// Delete user account
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "無法取得使用者資訊"
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        // Delete user data from Firestore first
        userRepository.deleteUserInfo()
            .flatMap { _ -> AnyPublisher<Void, Error> in
                // Then delete Firebase Auth account
                return Future<Void, Error> { promise in
                    user.delete { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    }
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .finished:
                        self?.authStateManager.isAuthenticated = false
                        self?.authStateManager.userInfo = nil
                        UserManager.shared.userInfo = UserInfo()
                        completion(true)
                    case .failure(let error):
                        self?.errorMessage = "刪除帳號失敗: \(error.localizedDescription)"
                        completion(false)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    /// Retry after error
    func retry() {
        errorMessage = nil
        if let userInfo = userInfo {
            fetchRecords()
        }
    }

    // MARK: - Private Methods

    private func setupUserObserver() {
        // Observe user info from AuthStateManager
        authStateManager.$userInfo
            .sink { [weak self] userInfo in
                self?.userInfo = userInfo
                self?.editedUserName = userInfo?.userName ?? ""
                self?.totalDistance = userInfo?.totalLength ?? 0

                // Fetch records when user info is available
                if userInfo != nil {
                    self?.fetchRecords()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var formattedTotalDistance: String {
        return String(format: "%.2f km", totalDistance)
    }

    var formattedTotalGroups: String {
        return "\(userInfo?.totalGroups ?? 0)"
    }

    var formattedTotalFriends: String {
        return "\(userInfo?.totalFriends ?? 0)"
    }

    // MARK: - Deinit
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Factory
extension ProfileViewModel {
    /// Create ProfileViewModel with repositories from container
    static func create(
        userRepository: UserRepositoryProtocol,
        recordRepository: RecordRepositoryProtocol,
        authStateManager: AuthStateManager
    ) -> ProfileViewModel {
        ProfileViewModel(
            userRepository: userRepository,
            recordRepository: recordRepository,
            authStateManager: authStateManager
        )
    }
}
