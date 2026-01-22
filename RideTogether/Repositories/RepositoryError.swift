//
//  RepositoryError.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Foundation

/// Unified error type for all repository operations
enum RepositoryError: LocalizedError {
    case notFound
    case unauthorized
    case invalidData
    case networkError(Error)
    case firestoreError(Error)
    case storageError(Error)
    case decodingError(Error)
    case unknown(Error)
    case emptyUserId
    case invalidRequest(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .invalidData:
            return "The data provided is invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .firestoreError(let error):
            return "Database error: \(error.localizedDescription)"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        case .emptyUserId:
            return "User ID is empty or invalid."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        }
    }

    /// Convert generic error to RepositoryError
    static func from(_ error: Error) -> RepositoryError {
        if let repositoryError = error as? RepositoryError {
            return repositoryError
        }

        if error is DecodingError {
            return .decodingError(error)
        }

        return .unknown(error)
    }
}
