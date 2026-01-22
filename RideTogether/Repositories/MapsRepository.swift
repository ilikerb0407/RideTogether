//
//  MapsRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import FirebaseFirestore
import Foundation

/// Protocol defining maps-related data operations
protocol MapsRepositoryProtocol {
    func fetchRoutes() -> AnyPublisher<[Route], Error>
    func fetchRecords() -> AnyPublisher<[Record], Error>
    func fetchSaveMaps(uid: String) -> AnyPublisher<[Record], Error>
    func deleteRecord(recordId: String) -> AnyPublisher<Void, Error>
}

/// Repository handling maps and routes data operations with Combine
final class MapsRepository: MapsRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: MapsManager
    private let db: Firestore

    // MARK: - Caching
    private var sharedRoutesPublisher: AnyPublisher<[Route], Error>?

    // MARK: - Init
    init(
        manager: MapsManager = .shared,
        db: Firestore = Firestore.firestore()
    ) {
        self.manager = manager
        self.db = db
    }

    // MARK: - Public Methods

    func fetchRoutes() -> AnyPublisher<[Route], Error> {
        Future<[Route], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "MapsRepository", code: -1))))
                return
            }

            self.manager.fetchRoutes { result in
                promise(result)
            }
        }
        .retry(1) // Retry once on failure for network resilience
        .catch { error -> AnyPublisher<[Route], Error> in
            // Log error and return empty array as fallback
            print("Failed to fetch routes: \(error.localizedDescription)")
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Optimized version with .share() for multiple subscribers
    /// Use this when multiple components need the same routes data
    func fetchRoutesShared() -> AnyPublisher<[Route], Error> {
        if let sharedPublisher = sharedRoutesPublisher {
            return sharedPublisher
        }

        let publisher = fetchRoutes()
            .share() // Share single network request among multiple subscribers
            .eraseToAnyPublisher()

        sharedRoutesPublisher = publisher
        return publisher
    }

    func fetchRecords() -> AnyPublisher<[Record], Error> {
        Future<[Record], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "MapsRepository", code: -1))))
                return
            }

            self.manager.fetchRecords { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchSaveMaps(uid: String) -> AnyPublisher<[Record], Error> {
        Future<[Record], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "MapsRepository", code: -1))))
                return
            }

            guard !uid.isEmpty else {
                promise(.failure(RepositoryError.emptyUserId))
                return
            }

            self.manager.fetchSavemaps { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func deleteRecord(recordId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "MapsRepository", code: -1))))
                return
            }

            guard !recordId.isEmpty else {
                promise(.failure(RepositoryError.invalidRequest("Record ID is empty")))
                return
            }

            self.manager.deleteDbRecords(recordId: recordId) { result in
                promise(result.map { _ in () })
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Fetch routes filtered by type
    func fetchRoutes(byType routeType: Int) -> AnyPublisher<[Route], Error> {
        fetchRoutes()
            .map { routes in
                routes.filter { $0.routeTypes == routeType }
            }
            .eraseToAnyPublisher()
    }

    /// Fetch records filtered by user
    func fetchRecords(byUserId userId: String) -> AnyPublisher<[Record], Error> {
        fetchRecords()
            .map { records in
                records.filter { $0.uid == userId }
            }
            .eraseToAnyPublisher()
    }
}
