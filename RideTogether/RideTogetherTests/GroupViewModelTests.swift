//
//  GroupViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that GroupViewModel — fetching groups filtered by block
//  list, fetching host user data, listening for join requests, and
//  search — can be tested with zero network calls, and includes
//  regression tests for the bugs found while extracting this logic out
//  of GroupViewController (see GroupViewModel.swift's header comment for
//  the full explanation).

import XCTest
@testable import RideTogether
import FirebaseFirestore

// MARK: - Fakes

private class FakeGroupManager: GroupManaging {
    var userId: String = "mock-uid"

    var stubbedFetchGroupsResult: Result<[Group], Error> = .success([])
    var stubbedRequestsResult: Result<[Request], Error> = .success([])

    func buildTeam(group _: inout Group, completion _: (Result<String, Error>) -> Void) {}

    func fetchGroups(completion: @escaping (Result<[Group], Error>) -> Void) {
        completion(stubbedFetchGroupsResult)
    }

    func requestListener(completion: @escaping (Result<[Request], Error>) -> Void) {
        completion(stubbedRequestsResult)
    }

    func updateTeam(group _: Group, completion _: (Result<String, Error>) -> Void) {}

    func sendRequest(request _: Request, completion _: (Result<String, Error>) -> Void) {}

    func leaveGroup(groupId _: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(""))
    }

    func addRequestListener(completion: @escaping (Result<[Request], Error>) -> Void) -> ListenerRegistration {
        completion(stubbedRequestsResult)
        return FakeListenerRegistration()
    }

    func addUserToGroup(groupId _: String, userId _: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(""))
    }

    func removeRequest(groupId _: String, userId _: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(""))
    }
}

private class FakeListenerRegistration: NSObject, ListenerRegistration {
    func remove() {}
}

private func makeGroup(hostId: String, userIds: [String], isExpired: Bool?, name: String = "route", secondsFromNow: Int = 0) -> Group {
    var group = Group()
    group.hostId = hostId
    group.userIds = userIds
    group.isExpired = isExpired
    group.routeName = name
    group.date = Timestamp(seconds: Int64(secondsFromNow), nanoseconds: 0)
    return group
}

private func makeViewModel(groupManager: FakeGroupManager = FakeGroupManager(), userManager: MockUserManager = MockUserManager()) -> GroupViewModel {
    GroupViewModel(groupManager: groupManager, userManager: userManager)
}

// MARK: - Tests

final class GroupViewModelTests: XCTestCase {
    func testFetchGroupData_regressionForNilBlockListBug_nilBlockListDoesNotHideEveryGroup() {
        // Regression test: the original filter was
        // `blockList?.contains(hostId) == false`, which for a nil
        // blockList evaluates to `nil == false` (false) for every group,
        // hiding everything instead of showing everyone.
        let groupManager = FakeGroupManager()
        groupManager.stubbedFetchGroupsResult = .success([
            makeGroup(hostId: "alice", userIds: ["someone-else"], isExpired: false),
        ])
        let userManager = MockUserManager()
        userManager.userInfo.blockList = nil

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchGroupData { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.inActivityGroup.count, 1, "a nil block list must not hide every group")
    }

    func testFetchGroupData_filtersOutGroupsFromBlockedHosts() {
        let groupManager = FakeGroupManager()
        groupManager.stubbedFetchGroupsResult = .success([
            makeGroup(hostId: "alice", userIds: ["someone-else"], isExpired: false),
            makeGroup(hostId: "bob", userIds: ["someone-else"], isExpired: false),
        ])
        let userManager = MockUserManager()
        userManager.userInfo.blockList = ["bob"]

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchGroupData { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.inActivityGroup.map(\.hostId), ["alice"])
    }

    func testFetchGroupData_regressionForIsExpiredForceUnwrapCrash_nilIsExpiredDoesNotCrashAndIsTreatedAsNotExpired() {
        // Regression test: the original rearrangeMyGroup did
        // `groups.filter { !$0.isExpired! }`, which force-unwraps an
        // optional Bool and crashes if isExpired is nil. A group with
        // nil isExpired (belonging to the current user, so it lands in
        // myGroups) must not crash, and should be treated as not expired.
        let groupManager = FakeGroupManager()
        let userManager = MockUserManager()
        userManager.userInfo.uid = "me"
        groupManager.stubbedFetchGroupsResult = .success([
            makeGroup(hostId: "me", userIds: ["me"], isExpired: nil),
        ])

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchGroupData { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.myGroups.count, 1)
    }

    func testFetchGroupData_splitsIntoMyGroupsAndActiveGroups() {
        let groupManager = FakeGroupManager()
        let userManager = MockUserManager()
        userManager.userInfo.uid = "me"
        groupManager.stubbedFetchGroupsResult = .success([
            makeGroup(hostId: "me", userIds: ["me"], isExpired: false),
            makeGroup(hostId: "someone", userIds: ["someone"], isExpired: false),
        ])

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchGroupData { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(sut.myGroups.map(\.hostId), ["me"])
        XCTAssertEqual(sut.inActivityGroup.count, 2)
    }

    func testAddRequestListener_regressionForNilBlockListBug_nilBlockListDoesNotHideEveryRequest() {
        let groupManager = FakeGroupManager()
        let request = Request(groupId: "g1", groupName: "route", hostId: "host", requestId: "req-1", createdTime: Timestamp(seconds: 0, nanoseconds: 0))
        groupManager.stubbedRequestsResult = .success([request])
        let userManager = MockUserManager()
        userManager.userInfo.blockList = nil

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)
        sut.addRequestListener()

        XCTAssertEqual(sut.requests.count, 1, "a nil block list must not hide every request")
    }

    func testUpdateSearch_filtersCurrentSourceByRouteNamePrefix() {
        let groupManager = FakeGroupManager()
        let userManager = MockUserManager()
        userManager.userInfo.uid = "me"
        groupManager.stubbedFetchGroupsResult = .success([
            makeGroup(hostId: "a", userIds: ["x"], isExpired: false, name: "河濱車道"),
            makeGroup(hostId: "b", userIds: ["y"], isExpired: false, name: "山區路線"),
        ])

        let sut = makeViewModel(groupManager: groupManager, userManager: userManager)

        let expectation = expectation(description: "fetch completed")
        sut.fetchGroupData { _ in expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        sut.updateSearch(text: "河濱")

        XCTAssertEqual(sut.currentGroups().map(\.routeName), ["河濱車道"])
    }
}
