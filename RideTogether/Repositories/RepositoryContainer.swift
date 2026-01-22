//
//  RepositoryContainer.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Foundation
import SwiftUI

/// Dependency injection container for all repositories
/// Provides a single source for repository instances
final class RepositoryContainer: ObservableObject {
    // MARK: - Phase 1 Repositories
    let userRepository: UserRepositoryProtocol

    // MARK: - Phase 2 Repositories
    let mapsRepository: MapsRepositoryProtocol

    // MARK: - Phase 3 Repositories
    let groupRepository: GroupRepositoryProtocol

    // MARK: - Phase 4+ Repositories (will be implemented later)
    // let recordRepository: RecordRepositoryProtocol
    // let locationRepository: LocationRepositoryProtocol
    // let weatherRepository: WeatherRepositoryProtocol
    // let ubikeRepository: UBikeRepositoryProtocol

    // MARK: - Init
    init(
        userRepository: UserRepositoryProtocol? = nil,
        mapsRepository: MapsRepositoryProtocol? = nil,
        groupRepository: GroupRepositoryProtocol? = nil
        // Add more repository parameters as they are implemented
    ) {
        // Use injected repository or create default
        self.userRepository = userRepository ?? UserRepository()
        self.mapsRepository = mapsRepository ?? MapsRepository()
        self.groupRepository = groupRepository ?? GroupRepository()

        // Initialize other repositories as they are implemented in future phases
    }

    /// Convenience initializer for production use
    static func live() -> RepositoryContainer {
        RepositoryContainer()
    }

    /// Create a container with mock repositories for testing
    #if DEBUG
    static func mock(
        userRepository: UserRepositoryProtocol? = nil,
        mapsRepository: MapsRepositoryProtocol? = nil,
        groupRepository: GroupRepositoryProtocol? = nil
    ) -> RepositoryContainer {
        RepositoryContainer(
            userRepository: userRepository,
            mapsRepository: mapsRepository,
            groupRepository: groupRepository
        )
    }
    #endif
}

// MARK: - Environment Key
struct RepositoryContainerKey: EnvironmentKey {
    static let defaultValue = RepositoryContainer.live()
}

extension EnvironmentValues {
    var repositories: RepositoryContainer {
        get { self[RepositoryContainerKey.self] }
        set { self[RepositoryContainerKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    /// Inject repositories into the SwiftUI environment
    func repositories(_ container: RepositoryContainer) -> some View {
        self.environment(\.repositories, container)
    }
}
