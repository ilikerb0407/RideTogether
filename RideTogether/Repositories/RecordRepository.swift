//
//  RecordRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import FirebaseFirestore
import FirebaseStorage
import Foundation

/// Protocol defining record-related data operations
protocol RecordRepositoryProtocol {
    func fetchRecords(forUserId userId: String) -> AnyPublisher<[Record], Error>
    func uploadRecord(fileName: String, fileURL: URL) -> AnyPublisher<URL, Error>
    func deleteRecord(fileName: String) -> AnyPublisher<Void, Error>
}

/// Repository handling GPS recording operations with Combine
final class RecordRepository: RecordRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: RecordManager
    private let db: Firestore
    private let storage: Storage

    // MARK: - Init
    init(
        manager: RecordManager = .shared,
        db: Firestore = Firestore.firestore(),
        storage: Storage = Storage.storage()
    ) {
        self.manager = manager
        self.db = db
        self.storage = storage
    }

    // MARK: - Public Methods

    /// Fetch records for a specific user
    func fetchRecords(forUserId userId: String) -> AnyPublisher<[Record], Error> {
        Future<[Record], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "RecordRepository", code: -1))))
                return
            }

            guard !userId.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            self.manager.fetchRecords { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Upload a GPX recording file to Firebase Storage
    /// Returns the download URL after successful upload
    func uploadRecord(fileName: String, fileURL: URL) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "RecordRepository", code: -1))))
                return
            }

            guard !fileName.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("File name is empty")))
                return
            }

            self.manager.uploadRecord(fileName: fileName, fileURL: fileURL) { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Delete a record from both Storage and Firestore
    func deleteRecord(fileName: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "RecordRepository", code: -1))))
                return
            }

            guard !fileName.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("File name is empty")))
                return
            }

            self.manager.deleteStorageRecords(fileName: fileName) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Upload GPX data directly (for in-memory GPX generation)
    func uploadGPXData(_ data: Data, fileName: String) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "RecordRepository", code: -1))))
                return
            }

            let userId = UserManager.shared.userInfo.uid
            guard !userId.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            let storageRef = self.storage.reference()
            let recordRef = storageRef.child("records").child(userId).child(fileName)

            recordRef.putData(data, metadata: nil) { _, error in
                if let error = error {
                    promise(.failure(RepositoryError.storageError(error)))
                    return
                }

                recordRef.downloadURL { result in
                    switch result {
                    case .success(let url):
                        // Also save to Firestore
                        self.saveRecordMetadata(fileName: fileName, fileURL: url)
                        promise(.success(url))
                    case .failure(let error):
                        promise(.failure(RepositoryError.storageError(error)))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func saveRecordMetadata(fileName: String, fileURL: URL) {
        let document = db.collection(Collection.records.rawValue).document()

        var record = Record()
        record.uid = UserManager.shared.userInfo.uid
        record.recordId = document.documentID
        record.recordName = fileName
        record.recordRef = fileURL.absoluteString
        record.pictureRef = UserManager.shared.userInfo.pictureRef

        do {
            try document.setData(from: record)
        } catch {
            print("Error saving record metadata: \(error)")
        }
    }
}
