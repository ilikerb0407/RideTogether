//
//  RouteViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  RouteViewController: saving a route to the user's saved maps, blocking
//  a route's uploader, and computing the theme label shown for this list
//  of routes.
//
//  RouteViewController had the same architecture issue we already fixed
//  in RecommendViewController: its own `uploadRecordToSavemaps` held a
//  separate Firestore instance and wrote directly into the "Savemaps"
//  collection, bypassing MapsManager. This ViewModel calls
//  `MapsManager.addToSavemaps` (added when we fixed the same issue in
//  RecommendViewModel) instead.

import Foundation

enum RouteViewModelError: Error, Equatable {
    case cannotBlockSelf
    /// The route has no uploader uid at all — this is one of the app's
    /// seeded/default routes, not a user-generated one, so there's no one
    /// to block. Matches the original "無法封鎖預設的地圖" message.
    case missingUploaderId
}

class RouteViewModel {
    
    // MARK: - Binding
    /// 當資料更新時通知 VC 刷新 UI
    var onRoutesUpdated: (() -> Void)?
    
    private(set) var routes: [RouteModel] {
        didSet {
            onRoutesUpdated?()
        }
    }

    private let mapsManager: MapsManaging
    private let userManager: UserManaging

    init(
        routes: [RouteModel] = [],
        mapsManager: MapsManaging = MapsManager.shared,
        userManager: UserManaging = UserManager.shared
    ) {
        self.routes = routes
        self.mapsManager = mapsManager
        self.userManager = userManager
    }

    // MARK: - Data Source Helpers for View
    
    func updateRoutes(_ routes: [RouteModel]) {
        self.routes = routes
    }
    
    var numberOfItems: Int {
        routes.count
    }
    
    func route(at index: Int) -> RouteModel? {
        guard routes.indices.contains(index) else { return nil }
        return routes[index]
    }

    /// The label shown at the top of the list, derived from the category
    /// of the first route.
    var themeLabel: String {
        guard let category = routes.first?.routeTypes else { return "" }

        switch category {
        case 0: return RouteCategory.userOne.rawValue
        case 1: return RouteCategory.recommendOne.rawValue
        case 2: return RouteCategory.riverOne.rawValue
        case 3: return RouteCategory.mountainOne.rawValue
        default: return ""
        }
    }

    // MARK: - Business Logic Operations
    
    func saveToSavemaps(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let route = route(at: index) else { return }

        mapsManager.addToSavemaps(
            fileName: route.routeName,
            fileRef: route.routeMap,
            userId: userManager.userInfo.uid,
            userPhoto: userManager.userInfo.pictureRef ?? "",
            completion: completion
        )
    }

    func blockUploader(ofRouteAt index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let route = route(at: index) else { return }
        
        // 修正順序：先確定是否有 uploader ID，再檢查是否為使用者本人
        guard let targetUserId = route.uid, !targetUserId.isEmpty else {
            completion(.failure(RouteViewModelError.missingUploaderId))
            return
        }

        if userManager.userInfo.uid == targetUserId {
            completion(.failure(RouteViewModelError.cannotBlockSelf))
            return
        }

        userManager.blockUser(blockUserId: targetUserId)
        userManager.userInfo.blockList?.append(targetUserId)
        completion(.success(()))
    }
}
