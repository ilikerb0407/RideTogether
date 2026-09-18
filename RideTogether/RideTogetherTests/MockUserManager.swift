//
//  MockUserManager.swift
//  RideTogetherTests
//
//  A fake `UserManaging` used in tests so that ViewController logic can be
//  verified without ever touching real Firebase/network calls. Every method
//  just records how it was called and/or calls its completion synchronously
//  with a canned result — enough to drive assertions in the tests that use
//  it.
//

import Foundation
@testable import RideTogether

class MockUserManager: UserManaging {
    var userId: String? = "mock-uid"
    var userInfo = UserInfo()

    // MARK: - Call tracking, so tests can assert *how* this mock was used

    var deleteUserInfoCallCount = 0
    var deleteUserFromGroupCallCount = 0
    var deleteUserRequestsCallCount = 0
    var deleteUserSharemapsCallCount = 0
    var updateUserNameCallCount = 0
    var updateUserGroupRecordsCallCount = 0
    var updateUserTrackLengthCallCount = 0
    var lastUpdatedTrackLength: Double?
    var blockUserCallCount = 0
    var lastBlockedUserId: String?

    // MARK: - UserManaging

    func deleteUserInfo(uid: String) {
        deleteUserInfoCallCount += 1
    }

    func deleteUserFromGroup(uid: String) {
        deleteUserFromGroupCallCount += 1
    }

    func deleteUserRequests(uid: String) {
        deleteUserRequestsCallCount += 1
    }

    func deleteUserSharemaps(uid: String) {
        deleteUserSharemapsCallCount += 1
    }

    func signUpUserInfo(userInfo: UserInfo, completion: @escaping (Result<String, Error>) -> Void) {
        self.userInfo = userInfo
        completion(.success("mock-success"))
    }

    func fetchUserInfo(uid: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        completion(.success(userInfo))
    }

    func uploadUserPicture(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        completion(.success(URL(string: "https://example.com/mock.jpg")!))
    }

    func updateImageToDb(fileURL: URL) {
        userInfo.pictureRef = fileURL.absoluteString
    }

    func updateUserName(name: String) {
        updateUserNameCallCount += 1
        userInfo.userName = name
    }

    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int) {
        updateUserGroupRecordsCallCount += 1
        userInfo.totalGroups = numOfGroups
        userInfo.totalFriends = numOfPartners
    }

    func updateUserTrackLength(length: Double) {
        updateUserTrackLengthCallCount += 1
        lastUpdatedTrackLength = length
        userInfo.totalLength += length
    }

    func blockUser(blockUserId: String) {
        blockUserCallCount += 1
        lastBlockedUserId = blockUserId
        userInfo.blockList?.append(blockUserId)
    }
}
