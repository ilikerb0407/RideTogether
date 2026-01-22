//
//  GroupRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import FirebaseFirestore
import Foundation

/// Protocol defining group-related data operations
protocol GroupRepositoryProtocol {
    func observeRequests() -> AnyPublisher<[Request], Error>
    func fetchGroups() -> AnyPublisher<[Group], Error>
    func createGroup(_ group: Group) -> AnyPublisher<String, Error>
    func sendRequest(_ request: Request) -> AnyPublisher<Void, Error>
    func addUserToGroup(groupId: String, userId: String) -> AnyPublisher<Void, Error>
    func leaveGroup(groupId: String) -> AnyPublisher<Void, Error>
    func removeRequest(groupId: String, userId: String) -> AnyPublisher<Void, Error>
    func updateGroup(_ group: Group) -> AnyPublisher<Void, Error>
}

/// Repository handling group data operations with Combine
/// CRITICAL: This repository fixes the memory leak in GroupManager by properly managing
/// Firestore snapshot listeners through Combine Publishers
final class GroupRepository: GroupRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: GroupManager
    private let db: Firestore

    // MARK: - Init
    init(
        manager: GroupManager = .shared,
        db: Firestore = Firestore.firestore()
    ) {
        self.manager = manager
        self.db = db
    }

    // MARK: - Public Methods

    /// Observe requests in real-time using Combine Publisher
    /// CRITICAL FIX: This replaces GroupManager.addRequestListener which had a memory leak
    /// The FirestorePublisher properly manages ListenerRegistration lifecycle
    func observeRequests() -> AnyPublisher<[Request], Error> {
        let userId = UserManager.shared.userInfo.uid

        guard !userId.isEmpty else {
            return Fail(error: RepositoryError.emptyUserId)
                .eraseToAnyPublisher()
        }

        let query = db.collection(Collection.requests.rawValue)
            .whereField("host_id", isEqualTo: userId)

        // Use FirestorePublisher which properly manages the snapshot listener
        return FirestorePublisher<[Request]>(query: query)
            .map { (requests: [Request]) in
                // Sort by creation time
                requests.sorted { $0.createdTime.seconds > $1.createdTime.seconds }
            }
            .catch { error -> AnyPublisher<[Request], Error> in
                // On error, log and return empty array to keep UI functional
                print("Error observing requests: \(error.localizedDescription)")
                return Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .mapError { error in
                RepositoryError.firestoreError(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchGroups() -> AnyPublisher<[Group], Error> {
        Future<[Group], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            self.manager.fetchGroups { result in
                promise(result)
            }
        }
        .retry(1) // Retry once on network failure
        .catch { error -> AnyPublisher<[Group], Error> in
            // Graceful degradation - return empty array on error
            print("Failed to fetch groups: \(error.localizedDescription)")
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func createGroup(_ group: Group) -> AnyPublisher<String, Error> {
        Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            var mutableGroup = group
            self.manager.buildTeam(group: &mutableGroup) { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func sendRequest(_ request: Request) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            self.manager.sendRequest(request: request) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func addUserToGroup(groupId: String, userId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            guard !groupId.isEmpty, !userId.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("Group ID or User ID is empty")))
                return
            }

            self.manager.addUserToGroup(groupId: groupId, userId: userId) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func leaveGroup(groupId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            guard !groupId.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("Group ID is empty")))
                return
            }

            self.manager.leaveGroup(groupId: groupId) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func removeRequest(groupId: String, userId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            guard !groupId.isEmpty, !userId.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("Group ID or User ID is empty")))
                return
            }

            self.manager.removeRequest(groupId: groupId, userId: userId) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func updateGroup(_ group: Group) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "GroupRepository", code: -1))))
                return
            }

            self.manager.updateTeam(group: group) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
