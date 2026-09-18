//
//  RideTogetherTests.swift
//  RideTogetherTests
//
//  Created by Kai Fu Jhuang on 2022/5/20.
//

@testable import RideTogether
import XCTest

class RideTogetherTests: XCTestCase {
    var sut: URLSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = URLSession(configuration: .default)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testApiCallCompletes() throws {
        // given
        let urlString = "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json"
        let url = URL(string: urlString)!
        let promise = expectation(description: "Completion handler invoked")
        var statusCode: Int?
        var responseError: Error?

        // when
        let dataTask = sut.dataTask(with: url) { _, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
        }
        dataTask.resume()
        wait(for: [promise], timeout: 10)

        // then
        XCTAssertNil(responseError)
        XCTAssertEqual(statusCode, 200)
    }

    // MARK: - Dependency-injection demonstration
    //
    // This test hits no network and no Firebase at all. It's only possible
    // because ProfileViewController now depends on `UserManaging` (a
    // protocol) instead of calling `UserManager.shared` directly, so a
    // `MockUserManager` can be swapped in. Compare this to
    // `testApiCallCompletes` above, which is a real network call and the
    // only test that existed in this project before.

    func testProfileViewController_canHaveItsUserManagerSwappedForATestDouble() throws {
        // given
        let mockUserManager = MockUserManager()
        let sut = ProfileViewController(nibName: nil, bundle: nil)

        // when
        sut.userManager = mockUserManager

        // then
        // Before this refactor, ProfileViewController called
        // `UserManager.shared` directly everywhere, so there was no seam to
        // substitute a fake here — any test exercising this VC's logic
        // would have hit real Firebase. Confirming the property actually
        // holds our mock (not silently falling back to the real
        // `UserManager.shared` singleton) demonstrates the injection point
        // is wired correctly.
        XCTAssertTrue(sut.userManager is MockUserManager)
        XCTAssertEqual(sut.userId, mockUserManager.userInfo.uid)
    }

    func testMockUserManager_updateUserTrackLength_accumulatesOntoExistingTotal() throws {
        // given
        let mockUserManager = MockUserManager()
        mockUserManager.userInfo.totalLength = 10.0

        // when
        mockUserManager.updateUserTrackLength(length: 5.0)

        // then
        XCTAssertEqual(mockUserManager.userInfo.totalLength, 15.0)
        XCTAssertEqual(mockUserManager.updateUserTrackLengthCallCount, 1)
        XCTAssertEqual(mockUserManager.lastUpdatedTrackLength, 5.0)
    }
}
