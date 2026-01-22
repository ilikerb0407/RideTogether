//
//  FirestorePublisher.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import FirebaseFirestore

/// Custom Combine Publisher for Firestore snapshot listeners
/// This publisher properly manages ListenerRegistration to prevent memory leaks
struct FirestorePublisher<Output>: Publisher {
    typealias Failure = Error

    private let query: Query
    private let includeMetadataChanges: Bool
    private let decoder: (QueryDocumentSnapshot) throws -> Output

    init(
        query: Query,
        includeMetadataChanges: Bool = false,
        decoder: @escaping (QueryDocumentSnapshot) throws -> Output
    ) {
        self.query = query
        self.includeMetadataChanges = includeMetadataChanges
        self.decoder = decoder
    }

    func receive<S>(subscriber: S) where S: Subscriber,
                    Failure == S.Failure,
                    Output == S.Input {
        let subscription = FirestoreSubscription(
            subscriber: subscriber,
            query: query,
            includeMetadataChanges: includeMetadataChanges,
            decoder: decoder
        )
        subscriber.receive(subscription: subscription)
    }
}

private final class FirestoreSubscription<S: Subscriber, Output>: Subscription
    where S.Input == Output, S.Failure == Error {

    private var subscriber: S?
    private var listenerRegistration: ListenerRegistration?

    init(
        subscriber: S,
        query: Query,
        includeMetadataChanges: Bool,
        decoder: @escaping (QueryDocumentSnapshot) throws -> Output
    ) {
        self.subscriber = subscriber

        // Store ListenerRegistration for proper cleanup
        listenerRegistration = query.addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
            if let error = error {
                subscriber.receive(completion: .failure(error))
                return
            }

            guard let documents = snapshot?.documents else { return }

            do {
                let items = try documents.map { try decoder($0) }
                _ = subscriber.receive(items as! S.Input)
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        // CRITICAL: Remove listener to prevent memory leaks
        listenerRegistration?.remove()
        listenerRegistration = nil
        subscriber = nil
    }
}

// MARK: - Convenience Extensions

extension FirestorePublisher where Output: Decodable {
    /// Convenience initializer for Decodable types
    init(query: Query, includeMetadataChanges: Bool = false) {
        self.init(
            query: query,
            includeMetadataChanges: includeMetadataChanges,
            decoder: { document in
                try document.data(as: Output.self, decoder: Firestore.Decoder())
            }
        )
    }
}

/// Single document publisher
struct FirestoreDocumentPublisher<Output>: Publisher {
    typealias Failure = Error

    private let documentReference: DocumentReference
    private let includeMetadataChanges: Bool
    private let decoder: (DocumentSnapshot) throws -> Output

    init(
        documentReference: DocumentReference,
        includeMetadataChanges: Bool = false,
        decoder: @escaping (DocumentSnapshot) throws -> Output
    ) {
        self.documentReference = documentReference
        self.includeMetadataChanges = includeMetadataChanges
        self.decoder = decoder
    }

    func receive<S>(subscriber: S) where S: Subscriber,
                    Failure == S.Failure,
                    Output == S.Input {
        let subscription = FirestoreDocumentSubscription(
            subscriber: subscriber,
            documentReference: documentReference,
            includeMetadataChanges: includeMetadataChanges,
            decoder: decoder
        )
        subscriber.receive(subscription: subscription)
    }
}

private final class FirestoreDocumentSubscription<S: Subscriber, Output>: Subscription
    where S.Input == Output, S.Failure == Error {

    private var subscriber: S?
    private var listenerRegistration: ListenerRegistration?

    init(
        subscriber: S,
        documentReference: DocumentReference,
        includeMetadataChanges: Bool,
        decoder: @escaping (DocumentSnapshot) throws -> Output
    ) {
        self.subscriber = subscriber

        listenerRegistration = documentReference.addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { snapshot, error in
            if let error = error {
                subscriber.receive(completion: .failure(error))
                return
            }

            guard let snapshot = snapshot else { return }

            do {
                let item = try decoder(snapshot)
                _ = subscriber.receive(item as! S.Input)
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        subscriber = nil
    }
}

extension FirestoreDocumentPublisher where Output: Decodable {
    init(documentReference: DocumentReference, includeMetadataChanges: Bool = false) {
        self.init(
            documentReference: documentReference,
            includeMetadataChanges: includeMetadataChanges,
            decoder: { snapshot in
                try snapshot.data(as: Output.self, decoder: Firestore.Decoder())
            }
        )
    }
}
