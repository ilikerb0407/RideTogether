//
//  GroupViewModel.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import Foundation
import SwiftUI
import FirebaseFirestore

/// ViewModel for Group feature following MVVM + Combine architecture
/// Manages group list, requests, and real-time updates
final class GroupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var requests: [Request] = []
    @Published var groups: [Group] = []
    @Published var filteredGroups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateGroupSheet = false
    @Published var selectedGroup: Group?

    // MARK: - Dependencies
    private let repository: GroupRepositoryProtocol

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init (Dependency Injection)
    init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Start listening to real-time requests updates
    /// This replaces the memory leak-prone GroupManager.addRequestListener
    func startListening() {
        repository.observeRequests()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] requests in
                    self?.requests = requests
                }
            )
            .store(in: &cancellables)
    }

    /// Fetch all groups
    func fetchGroups() {
        isLoading = true
        errorMessage = nil

        repository.fetchGroups()
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] groups in
                    self?.groups = groups
                    self?.filteredGroups = groups
                }
            )
            .store(in: &cancellables)
    }

    /// Create a new group
    func createGroup(_ group: Group) {
        repository.createGroup(group)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] groupId in
                    print("Group created with ID: \(groupId)")
                    // Refresh groups after creation
                    self?.fetchGroups()
                    self?.showCreateGroupSheet = false
                }
            )
            .store(in: &cancellables)
    }

    /// Send a join request to a group
    func sendJoinRequest(to group: Group) {
        let userInfo = UserManager.shared.userInfo

        let request = Request(
            groupId: group.groupId,
            groupName: group.groupName,
            hostId: group.hostId,
            requestId: userInfo.uid,
            createdTime: Timestamp()
        )

        repository.sendRequest(request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "發送請求失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] in
                    print("Join request sent successfully")
                    self?.errorMessage = "已發送加入請求"
                }
            )
            .store(in: &cancellables)
    }

    /// Accept a join request
    func acceptRequest(_ request: Request) {
        // Add user to group
        repository.addUserToGroup(groupId: request.groupId, userId: request.requestId)
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                // Then remove the request
                guard let self = self else {
                    return Fail(error: RepositoryError.unknown(NSError(domain: "GroupViewModel", code: -1)))
                        .eraseToAnyPublisher()
                }
                return self.repository.removeRequest(groupId: request.groupId, userId: request.requestId)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "接受請求失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] in
                    print("Request accepted successfully")
                    // Requests will be automatically updated via real-time listener
                    self?.fetchGroups() // Refresh groups to show updated member count
                }
            )
            .store(in: &cancellables)
    }

    /// Reject a join request
    func rejectRequest(_ request: Request) {
        repository.removeRequest(groupId: request.groupId, userId: request.requestId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "拒絕請求失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: {
                    print("Request rejected successfully")
                    // Requests will be automatically updated via real-time listener
                }
            )
            .store(in: &cancellables)
    }

    /// Leave a group
    func leaveGroup(_ group: Group) {
        repository.leaveGroup(groupId: group.groupId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "離開團隊失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] in
                    print("Left group successfully")
                    self?.fetchGroups()
                }
            )
            .store(in: &cancellables)
    }

    /// Filter groups based on search text
    func filterGroups(searchText: String) {
        if searchText.isEmpty {
            filteredGroups = groups
        } else {
            filteredGroups = groups.filter { group in
                group.groupName.localizedCaseInsensitiveContains(searchText) ||
                group.routeName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    /// Get unblocked requests (filter out blocked users)
    func getUnblockedRequests() -> [Request] {
        let userInfo = UserManager.shared.userInfo
        let blockList = userInfo.blockList ?? []

        return requests.filter { request in
            !blockList.contains(request.requestId)
        }
    }

    /// Retry after error
    func retry() {
        errorMessage = nil
        fetchGroups()
        startListening()
    }

    // MARK: - Deinit
    deinit {
        // Cancellables are automatically cleaned up
        cancellables.removeAll()
    }
}

// MARK: - Factory
extension GroupViewModel {
    /// Create GroupViewModel with repository from container
    static func create(with repository: GroupRepositoryProtocol) -> GroupViewModel {
        GroupViewModel(repository: repository)
    }
}
