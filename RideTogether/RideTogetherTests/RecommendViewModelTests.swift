//
//  RecommendViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that RecommendViewModel — fetching the shared-record wall
//  filtered by block list, saving a record, and blocking its uploader —
//  can be tested with zero network calls, and includes a regression test
//  for a block-list filtering bug found while extracting this logic out
//  of RecommendViewController (see RecommendViewModel.swift's header
//  comment for the full explanation).

import XCTest
@testable import RideTogether

// MARK: - Fakes

private class FakeMapsManager: MapsManaging {
    var userId: String = "mock-uid"
    var savemaps: [String] = []

    var stubbedFetchRecordsResult: Result<[Record], Error> = .success([])
    var addToSavemapsResult: Result<Void, Error> = .success(())
    private(set) var addToSavemapsCallCount = 0

    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        completion(stubbedFetchRecordsResult)
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

private func makeRecord(uid: String, name: String) -> Record {
    var record = Record()
    record.uid = uid
    record.recordName = name
    return record
}

private func makeViewModel(mapsManager: FakeMapsManager = FakeMapsManager(), userManager: MockUserManager = MockUserManager()) -> RecommendViewModel {
    RecommendViewModel(mapsManager: mapsManager, userManager: userManager)
}

// MARK: - Tests

final class RecommendViewModelTests: XCTestCase {
    func testFetchRecords_filtersOutRecordsFromBlockedUsers() {
        let mapsManager = FakeMapsManager()
        mapsManager.stubbedFetchRecordsResult = .success([
            makeRecord(uid: "alice", name: "a.gpx"),
            makeRecord(uid: "bob", name: "b.gpx"),
        ])
        let userManager = MockUserManager()
        userManager.userInfo.blockList = ["bob"]
        let sut = makeViewModel(mapsManager: mapsManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.records.map(\.uid), ["alice"])
    }

    func testFetchRecords_regressionForNilBlockListBug_nilBlockListDoesNotHideEveryRecord() {
        // Regression test: the original filter was
        // `blockList?.contains(uid) == false`, which for a nil blockList
        // evaluates to `nil == false` (false) for every record, hiding
        // the entire wall instead of showing everyone. A nil block list
        // must behave the same as an empty one: nothing is filtered out.
        let mapsManager = FakeMapsManager()
        mapsManager.stubbedFetchRecordsResult = .success([
            makeRecord(uid: "alice", name: "a.gpx"),
            makeRecord(uid: "bob", name: "b.gpx"),
        ])
        let userManager = MockUserManager()
        userManager.userInfo.blockList = nil
        let sut = makeViewModel(mapsManager: mapsManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.records.count, 2, "a nil block list must not hide every record")
    }

    func testSaveToSavemaps_callsMapsManagerWithTheRecordAtGivenIndex() {
        let mapsManager = FakeMapsManager()
        mapsManager.stubbedFetchRecordsResult = .success([makeRecord(uid: "alice", name: "a.gpx")])
        let sut = makeViewModel(mapsManager: mapsManager)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let saveExpectation = expectation(description: "save completed")
        var receivedResult: Result<Void, Error>?
        sut.saveToSavemaps(at: 0) { result in
            receivedResult = result
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 1)

        XCTAssertEqual(mapsManager.addToSavemapsCallCount, 1)
        if case .failure = receivedResult { XCTFail("expected success") }
    }

    func testBlockUploader_targetIsSomeoneElse_callsUserManagerBlockUserAndAppendsToBlockList() {
        let mapsManager = FakeMapsManager()
        mapsManager.stubbedFetchRecordsResult = .success([makeRecord(uid: "bob", name: "b.gpx")])
        let userManager = MockUserManager()
        userManager.userInfo.uid = "alice"
        userManager.userInfo.blockList = []
        let sut = makeViewModel(mapsManager: mapsManager, userManager: userManager)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let blockExpectation = expectation(description: "block completed")
        var receivedResult: Result<Void, Error>?
        sut.blockUploader(ofRecordAt: 0) { result in
            receivedResult = result
            blockExpectation.fulfill()
        }
        wait(for: [blockExpectation], timeout: 1)

        XCTAssertEqual(userManager.blockUserCallCount, 1)
        XCTAssertEqual(userManager.lastBlockedUserId, "bob")
        XCTAssertEqual(userManager.userInfo.blockList, ["bob"])
        if case .failure = receivedResult { XCTFail("expected success") }
    }

    func testBlockUploader_targetIsSelf_failsWithoutCallingUserManagerBlockUser() {
        let mapsManager = FakeMapsManager()
        mapsManager.stubbedFetchRecordsResult = .success([makeRecord(uid: "alice", name: "a.gpx")])
        let userManager = MockUserManager()
        userManager.userInfo.uid = "alice"
        let sut = makeViewModel(mapsManager: mapsManager, userManager: userManager)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let blockExpectation = expectation(description: "block completed")
        var receivedResult: Result<Void, Error>?
        sut.blockUploader(ofRecordAt: 0) { result in
            receivedResult = result
            blockExpectation.fulfill()
        }
        wait(for: [blockExpectation], timeout: 1)

        XCTAssertEqual(userManager.blockUserCallCount, 0)
        guard case let .failure(error) = receivedResult else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(error as? RecommendViewModelError, .cannotBlockSelf)
    }
}
