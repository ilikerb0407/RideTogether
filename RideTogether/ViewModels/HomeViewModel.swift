//
//  HomeViewModel.swift
//  RideTogether
//
//  Created by Auto on 2026/01/22.
//

import Combine
import Foundation
import SwiftUI

/// ViewModel for Home feature following MVVM + Combine architecture
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var routes: [Route] = []
    @Published var records: [Record] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Grouped routes by type for display
    @Published var friendRoutes: [Route] = []
    @Published var recommendedRoutes: [Route] = []
    @Published var riverRoutes: [Route] = []
    @Published var mountainRoutes: [Route] = []

    // MARK: - Dependencies
    private let repository: MapsRepositoryProtocol

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init (Dependency Injection)
    init(repository: MapsRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Fetch all routes and group them by type
    func fetchRoutes() {
        isLoading = true
        errorMessage = nil

        repository.fetchRoutes()
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] routes in
                    self?.routes = routes
                    self?.groupRoutesByType(routes)
                }
            )
            .store(in: &cancellables)
    }

    /// Fetch records (shared maps)
    func fetchRecords() {
        repository.fetchRecords()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] records in
                    self?.records = records
                }
            )
            .store(in: &cancellables)
    }

    /// Fetch routes for a specific type
    func fetchRoutes(forType routeType: RoutesType) {
        repository.fetchRoutes(byType: routeType.rawValue)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] routes in
                    self?.updateRoutes(forType: routeType, with: routes)
                }
            )
            .store(in: &cancellables)
    }

    /// Retry loading after an error
    func retry() {
        errorMessage = nil
        fetchRoutes()
    }

    // MARK: - Private Methods

    private func groupRoutesByType(_ routes: [Route]) {
        friendRoutes = routes.filter { $0.routeTypes == RoutesType.userOne.rawValue }
        recommendedRoutes = routes.filter { $0.routeTypes == RoutesType.recommendOne.rawValue }
        riverRoutes = routes.filter { $0.routeTypes == RoutesType.riverOne.rawValue }
        mountainRoutes = routes.filter { $0.routeTypes == RoutesType.mountainOne.rawValue }
    }

    private func updateRoutes(forType type: RoutesType, with routes: [Route]) {
        switch type {
        case .userOne:
            friendRoutes = routes
        case .recommendOne:
            recommendedRoutes = routes
        case .riverOne:
            riverRoutes = routes
        case .mountainOne:
            mountainRoutes = routes
        }
    }

    /// Get routes for a specific type
    func routes(for type: RoutesType) -> [Route] {
        switch type {
        case .userOne:
            return friendRoutes
        case .recommendOne:
            return recommendedRoutes
        case .riverOne:
            return riverRoutes
        case .mountainOne:
            return mountainRoutes
        }
    }

    // MARK: - Deinit
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Factory
extension HomeViewModel {
    /// Create HomeViewModel with repository from container
    static func create(with repository: MapsRepositoryProtocol) -> HomeViewModel {
        HomeViewModel(repository: repository)
    }
}
