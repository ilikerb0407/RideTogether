//
//  UserRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

/// Protocol defining user-related data operations
protocol UserRepositoryProtocol {
    func fetchUserInfo(uid: String) -> AnyPublisher<UserInfo, Error>
    func signUpUserInfo(_ userInfo: UserInfo) -> AnyPublisher<Void, Error>
    func updateUserName(_ name: String) -> AnyPublisher<Void, Error>
    func uploadUserPicture(_ imageData: Data) -> AnyPublisher<URL, Error>
    func updateUserTrackLength(_ length: Double) -> AnyPublisher<Void, Error>
    func blockUser(_ blockUserId: String) -> AnyPublisher<Void, Error>
    func deleteUserInfo() -> AnyPublisher<Void, Error>
    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int) -> AnyPublisher<Void, Error>
}

/// Repository handling user data operations with Combine
final class UserRepository: UserRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: UserManager
    private let db: Firestore
    private let storage: Storage

    // MARK: - Init
    init(
        manager: UserManager = .shared,
        db: Firestore = Firestore.firestore(),
        storage: Storage = Storage.storage()
    ) {
        self.manager = manager
        self.db = db
        self.storage = storage
    }

    // MARK: - Public Methods

    func fetchUserInfo(uid: String) -> AnyPublisher<UserInfo, Error> {
        Future<UserInfo, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            self.manager.fetchUserInfo(uid: uid) { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func signUpUserInfo(_ userInfo: UserInfo) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            self.manager.signUpUserInfo(userInfo: userInfo) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func updateUserName(_ name: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            let uid = self.manager.userInfo.uid
            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            let post = [UserInfo.CodingKeys.userName.rawValue: name]
            let docRef = self.db.collection(Collection.users.rawValue).document(uid)

            docRef.updateData(post) { error in
                if let error = error {
                    promise(.failure(RepositoryError.firestoreError(error)))
                } else {
                    // Update local state
                    self.manager.userInfo.userName = name
                    promise(.success(()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func uploadUserPicture(_ imageData: Data) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            self.manager.uploadUserPicture(imageData: imageData) { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func updateUserTrackLength(_ length: Double) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            let uid = self.manager.userInfo.uid
            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            self.manager.userInfo.totalLength += length

            let post = [UserInfo.CodingKeys.totalLength.rawValue: self.manager.userInfo.totalLength]
            let docRef = self.db.collection(Collection.users.rawValue).document(uid)

            docRef.updateData(post) { error in
                if let error = error {
                    promise(.failure(RepositoryError.firestoreError(error)))
                } else {
                    promise(.success(()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func blockUser(_ blockUserId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            let uid = self.manager.userInfo.uid
            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            let docRef = self.db.collection(Collection.users.rawValue).document(uid)

            docRef.updateData([
                "block_list": FieldValue.arrayUnion([blockUserId])
            ]) { error in
                if let error = error {
                    promise(.failure(RepositoryError.firestoreError(error)))
                } else {
                    self.manager.userInfo.blockList?.append(blockUserId)
                    promise(.success(()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func deleteUserInfo() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            let uid = self.manager.userInfo.uid
            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            let document = self.db.collection(Collection.users.rawValue).document(uid)

            document.delete { error in
                if let error = error {
                    promise(.failure(RepositoryError.firestoreError(error)))
                } else {
                    promise(.success(()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UserRepository", code: -1))))
                return
            }

            let uid = self.manager.userInfo.uid
            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            let docRef = self.db.collection(Collection.users.rawValue).document(uid)

            let data: [String: Any] = [
                "total_groups": numOfGroups,
                "total_friends": numOfPartners
            ]

            docRef.updateData(data) { error in
                if let error = error {
                    promise(.failure(RepositoryError.firestoreError(error)))
                } else {
                    self.manager.userInfo.totalGroups = numOfGroups
                    self.manager.userInfo.totalFriends = numOfPartners
                    promise(.success(()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
