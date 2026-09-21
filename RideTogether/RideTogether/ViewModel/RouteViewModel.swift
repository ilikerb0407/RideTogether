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
    private(set) var routes: [RouteModel]

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

    /// RouteViewController receives its route list after the ViewModel
    /// already exists (assigned via `prepare(for:sender:)` from
    /// HomeViewController, not at init time), so `routes` needs to be
    /// settable after construction rather than purely init-only.
    func updateRoutes(_ routes: [RouteModel]) {
        self.routes = routes
    }

    /// The label shown at the top of the list, derived from the category
    /// of the first route (every route in one RouteViewController's list
    /// shares the same category, since they're all filtered from the same
    /// RouteCategory tapped on the home screen).
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

    func saveToSavemaps(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard routes.indices.contains(index) else { return }
        let route = routes[index]

        mapsManager.addToSavemaps(
            fileName: route.routeName,
            fileRef: route.routeMap,
            userId: userManager.userInfo.uid,
            userPhoto: userManager.userInfo.pictureRef ?? "",
            completion: completion
        )
    }

    /// Blocks the uploader of route `index`. Checks self-block before the
    /// missing-uploader case, matching the original's check order.
    func blockUploader(ofRouteAt index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard routes.indices.contains(index) else { return }
        let targetUserId = routes[index].uid

        if userManager.userInfo.uid == targetUserId {
            completion(.failure(RouteViewModelError.cannotBlockSelf))
            return
        }
        guard let targetUserId = targetUserId else {
            completion(.failure(RouteViewModelError.missingUploaderId))
            return
        }

        userManager.blockUser(blockUserId: targetUserId)
        userManager.userInfo.blockList?.append(targetUserId)
        completion(.success(()))
    }
}
