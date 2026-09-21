//
//  RouteViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that RouteViewModel — saving a route, blocking its
//  uploader (including the self-block and missing-uploader edge cases),
//  and computing the theme label — can be tested with zero network calls.

import XCTest
@testable import RideTogether

// MARK: - Fakes

private class FakeMapsManager: MapsManaging {
    var userId: String = "mock-uid"
    var savemaps: [String] = []

    var addToSavemapsResult: Result<Void, Error> = .success(())
    private(set) var addToSavemapsCallCount = 0

    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchRoutes(completion: @escaping (Result<[RouteModel], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchSavemaps(completion: @escaping (Result<[Record], Error>) -> Void) {
        completion(.success([]))
    }

    func deleteDbRecords(recordId _: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(""))
    }

    func addToSavemaps(fileName _: String, fileRef _: String, userId _: String, userPhoto _: String, completion: @escaping (Result<Void, Error>) -> Void) {
        addToSavemapsCallCount += 1
        completion(addToSavemapsResult)
    }
}

private func makeRoute(uid: String?, name: String, routeTypes: Int = 0) -> RouteModel {
    var route = RouteModel()
    route.uid = uid
    route.routeName = name
    route.routeTypes = routeTypes
    return route
}

private func makeViewModel(routes: [RouteModel] = [], mapsManager: FakeMapsManager = FakeMapsManager(), userManager: MockUserManager = MockUserManager()) -> RouteViewModel {
    RouteViewModel(routes: routes, mapsManager: mapsManager, userManager: userManager)
}

// MARK: - Tests

final class RouteViewModelTests: XCTestCase {
    func testThemeLabel_derivedFromFirstRoutesCategory() {
        XCTAssertEqual(makeViewModel(routes: [makeRoute(uid: "a", name: "n", routeTypes: 0)]).themeLabel, RouteCategory.userOne.rawValue)
        XCTAssertEqual(makeViewModel(routes: [makeRoute(uid: "a", name: "n", routeTypes: 1)]).themeLabel, RouteCategory.recommendOne.rawValue)
        XCTAssertEqual(makeViewModel(routes: [makeRoute(uid: "a", name: "n", routeTypes: 2)]).themeLabel, RouteCategory.riverOne.rawValue)
        XCTAssertEqual(makeViewModel(routes: [makeRoute(uid: "a", name: "n", routeTypes: 3)]).themeLabel, RouteCategory.mountainOne.rawValue)
    }

    func testThemeLabel_noRoutes_isEmpty() {
        XCTAssertEqual(makeViewModel(routes: []).themeLabel, "")
    }

    func testUpdateRoutes_replacesRoutesAndThemeLabel() {
        let sut = makeViewModel(routes: [makeRoute(uid: "a", name: "n", routeTypes: 0)])
        XCTAssertEqual(sut.themeLabel, RouteCategory.userOne.rawValue)

        sut.updateRoutes([makeRoute(uid: "b", name: "m", routeTypes: 2)])

        XCTAssertEqual(sut.routes.count, 1)
        XCTAssertEqual(sut.themeLabel, RouteCategory.riverOne.rawValue)
    }

    func testSaveToSavemaps_callsMapsManagerWithTheRouteAtGivenIndex() {
        let mapsManager = FakeMapsManager()
        let sut = makeViewModel(routes: [makeRoute(uid: "a", name: "n")], mapsManager: mapsManager)

        let expectation = expectation(description: "save completed")
        var receivedResult: Result<Void, Error>?
        sut.saveToSavemaps(at: 0) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mapsManager.addToSavemapsCallCount, 1)
        if case .failure = receivedResult { XCTFail("expected success") }
    }

    func testBlockUploader_targetIsSomeoneElse_succeeds() {
        let userManager = MockUserManager()
        userManager.userInfo.uid = "alice"
        userManager.userInfo.blockList = []
        let sut = makeViewModel(routes: [makeRoute(uid: "bob", name: "n")], userManager: userManager)

        let expectation = expectation(description: "block completed")
        var receivedResult: Result<Void, Error>?
        sut.blockUploader(ofRouteAt: 0) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(userManager.blockUserCallCount, 1)
        XCTAssertEqual(userManager.lastBlockedUserId, "bob")
        XCTAssertEqual(userManager.userInfo.blockList, ["bob"])
        if case .failure = receivedResult { XCTFail("expected success") }
    }

    func testBlockUploader_targetIsSelf_failsWithCannotBlockSelf_checkedBeforeMissingUploaderId() {
        // Regression test for the original check order: self-block is
        // checked before the nil-uploader case, so a route the current
        // user themselves uploaded must report cannotBlockSelf, not
        // missingUploaderId, even though both conditions could seem to
        // apply if checked in the other order for some malformed data.
        let userManager = MockUserManager()
        userManager.userInfo.uid = "alice"
        let sut = makeViewModel(routes: [makeRoute(uid: "alice", name: "n")], userManager: userManager)

        let expectation = expectation(description: "block completed")
        var receivedResult: Result<Void, Error>?
        sut.blockUploader(ofRouteAt: 0) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(userManager.blockUserCallCount, 0)
        guard case let .failure(error) = receivedResult else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? RouteViewModelError, .cannotBlockSelf)
    }

    func testBlockUploader_missingUploaderId_failsWithMissingUploaderId() {
        let userManager = MockUserManager()
        userManager.userInfo.uid = "alice"
        let sut = makeViewModel(routes: [makeRoute(uid: nil, name: "seeded route")], userManager: userManager)

        let expectation = expectation(description: "block completed")
        var receivedResult: Result<Void, Error>?
        sut.blockUploader(ofRouteAt: 0) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(userManager.blockUserCallCount, 0)
        guard case let .failure(error) = receivedResult else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? RouteViewModelError, .missingUploaderId)
    }
}
