//
//  TracksViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that TracksViewModel — fetching records, deleting one,
//  and the multi-step "share a record" flow that used to be spread
//  across TracksViewController with its own ad-hoc Storage/Firestore
//  instances — can now be tested with zero network calls, by injecting
//  fakes for RecordManaging, RecordSharingDownloading, RecordSharing,
//  GPXLengthCalculating, and UserManaging.

import Foundation
import XCTest
@testable import RideTogether

// MARK: - Fakes

private class FakeRecordManager: RecordManaging {
    var userId: String = "mock-uid"
    var userPhoto: String = "mock-photo-ref"

    var stubbedFetchResult: Result<[Record], Error> = .success([])
    var deleteStorageRecordsResult: Result<String, Error> = .success("Success")
    private(set) var deletedFileNames: [String] = []

    func uploadRecord(fileName _: String, fileURL _: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        completion(.failure(TestError.notStubbed))
    }

    func uploadRecordToDb(fileName _: String, fileURL _: URL) {}

    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        completion(stubbedFetchResult)
    }

    func fetchOneRecord(completion: @escaping (Result<Record, Error>) -> Void) {
        completion(.failure(TestError.notStubbed))
    }

    func deleteStorageRecords(fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        deletedFileNames.append(fileName)
        completion(deleteStorageRecordsResult)
    }

    func deleteDbRecords(fileName _: String) {}
}

private class FakeRecordSharingDownloader: RecordSharingDownloading {
    var stubbedResult: Result<URL, Error> = .success(URL(string: "https://example.com/mock.gpx")!)
    private(set) var requestedFileNames: [String] = []

    func downloadURL(userId _: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        requestedFileNames.append(fileName)
        completion(stubbedResult)
    }
}

private class FakeRecordSharing: RecordSharing {
    var addToSharedRecordsResult: Result<Void, Error> = .success(())
    var addToPopularRoutesResult: Result<Void, Error> = .success(())
    private(set) var sharedRecordCalls = 0
    private(set) var popularRouteCalls = 0
    private(set) var lastPopularRouteLength: String?

    func addToSharedRecords(fileName _: String, fileURL _: URL, userId _: String, userPhoto _: String, completion: @escaping (Result<Void, Error>) -> Void) {
        sharedRecordCalls += 1
        completion(addToSharedRecordsResult)
    }

    func addToPopularRoutes(fileName _: String, fileURL _: URL, userId _: String, userName _: String, userPhoto _: String, routeLength: String, completion: @escaping (Result<Void, Error>) -> Void) {
        popularRouteCalls += 1
        lastPopularRouteLength = routeLength
        completion(addToPopularRoutesResult)
    }
}

private class FakeGPXLengthCalculator: GPXLengthCalculating {
    var stubbedLength: Double? = 5000

    func totalLength(ofGPXAt _: URL) -> Double? {
        stubbedLength
    }
}

private enum TestError: Error {
    case notStubbed
}

private func makeRecord(name: String) -> Record {
    var record = Record()
    record.recordName = name
    return record
}

private func makeViewModel(
    recordManager: FakeRecordManager = FakeRecordManager(),
    downloader: FakeRecordSharingDownloader = FakeRecordSharingDownloader(),
    sharing: FakeRecordSharing = FakeRecordSharing(),
    lengthCalculator: FakeGPXLengthCalculator = FakeGPXLengthCalculator(),
    userManager: MockUserManager = MockUserManager()
) -> TracksViewModel {
    TracksViewModel(
        recordManager: recordManager,
        recordSharingStorage: downloader,
        recordSharing: sharing,
        gpxLengthCalculator: lengthCalculator,
        userManager: userManager
    )
}

// MARK: - Tests

final class TracksViewModelTests: XCTestCase {
    func testFetchRecords_success_populatesRecords() {
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "a"), makeRecord(name: "b")])
        let sut = makeViewModel(recordManager: recordManager)

        let expectation = expectation(description: "fetch completed")
        var receivedResult: Result<Void, Error>?

        sut.fetchRecords { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.records.count, 2)
        if case .failure = receivedResult { XCTFail("expected success") }
    }

    func testDeleteRecord_success_removesFromLocalRecordsAndCallsRecordManagerWithCorrectFileName() {
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "a"), makeRecord(name: "b")])
        let sut = makeViewModel(recordManager: recordManager)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let deleteExpectation = expectation(description: "delete completed")
        sut.deleteRecord(at: 0) { _ in deleteExpectation.fulfill() }
        wait(for: [deleteExpectation], timeout: 1)

        XCTAssertEqual(recordManager.deletedFileNames, ["a"])
        XCTAssertEqual(sut.records.count, 1)
        XCTAssertEqual(sut.records.first?.recordName, "b")
    }

    func testDeleteRecord_failure_doesNotRemoveFromLocalRecords() {
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "a")])
        recordManager.deleteStorageRecordsResult = .failure(TestError.notStubbed)
        let sut = makeViewModel(recordManager: recordManager)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let deleteExpectation = expectation(description: "delete completed")
        var receivedResult: Result<Void, Error>?
        sut.deleteRecord(at: 0) { result in
            receivedResult = result
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)

        XCTAssertEqual(sut.records.count, 1, "a failed delete must not remove the record locally")
        if case .success = receivedResult { XCTFail("expected failure") }
    }

    func testShareRecord_success_writesBothDocumentsAndIncludesComputedLength() {
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "ride.gpx")])
        let sharing = FakeRecordSharing()
        let lengthCalculator = FakeGPXLengthCalculator()
        lengthCalculator.stubbedLength = 12000
        let sut = makeViewModel(recordManager: recordManager, sharing: sharing, lengthCalculator: lengthCalculator)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let shareExpectation = expectation(description: "share completed")
        var receivedResult: Result<Void, Error>?
        sut.shareRecord(at: 0) { result in
            receivedResult = result
            shareExpectation.fulfill()
        }
        wait(for: [shareExpectation], timeout: 1)

        if case .failure = receivedResult { XCTFail("expected success") }
        XCTAssertEqual(sharing.sharedRecordCalls, 1)
        XCTAssertEqual(sharing.popularRouteCalls, 1)
        XCTAssertEqual(sharing.lastPopularRouteLength, "距離 : \(Double(12000).toDistance())")
    }

    func testShareRecord_downloadURLFails_neverAttemptsToWriteEitherDocument() {
        // Regression-style test for the original bug class this
        // refactor fixes: a failure partway through the share flow must
        // not silently proceed to write partial data.
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "ride.gpx")])
        let downloader = FakeRecordSharingDownloader()
        downloader.stubbedResult = .failure(TestError.notStubbed)
        let sharing = FakeRecordSharing()
        let sut = makeViewModel(recordManager: recordManager, downloader: downloader, sharing: sharing)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let shareExpectation = expectation(description: "share completed")
        var receivedResult: Result<Void, Error>?
        sut.shareRecord(at: 0) { result in
            receivedResult = result
            shareExpectation.fulfill()
        }
        wait(for: [shareExpectation], timeout: 1)

        if case .success = receivedResult { XCTFail("expected failure") }
        XCTAssertEqual(sharing.sharedRecordCalls, 0)
        XCTAssertEqual(sharing.popularRouteCalls, 0)
    }

    func testShareRecord_oneWriteFails_reportsFailureOverall() {
        let recordManager = FakeRecordManager()
        recordManager.stubbedFetchResult = .success([makeRecord(name: "ride.gpx")])
        let sharing = FakeRecordSharing()
        sharing.addToPopularRoutesResult = .failure(TestError.notStubbed)
        let sut = makeViewModel(recordManager: recordManager, sharing: sharing)

        let fetchExpectation = expectation(description: "fetch completed")
        sut.fetchRecords { _ in fetchExpectation.fulfill() }
        wait(for: [fetchExpectation], timeout: 1)

        let shareExpectation = expectation(description: "share completed")
        var receivedResult: Result<Void, Error>?
        sut.shareRecord(at: 0) { result in
            receivedResult = result
            shareExpectation.fulfill()
        }
        wait(for: [shareExpectation], timeout: 1)

        // Both writes were still attempted (they're independent
        // documents)...
        XCTAssertEqual(sharing.sharedRecordCalls, 1)
        XCTAssertEqual(sharing.popularRouteCalls, 1)
        // ...but the overall result must surface the failure, unlike the
        // original code, which had no way to report a partial failure at
        // all.
        if case .success = receivedResult { XCTFail("expected failure to be reported") }
    }
}
