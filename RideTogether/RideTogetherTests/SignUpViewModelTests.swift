//
//  SignUpViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that SignUpViewModel — creating an account, signing in,
//  and the new-vs-returning-user branching — can be tested with zero
//  network/Firebase Auth calls, and includes regression tests for the
//  bugs found while consolidating this logic out of SignUpViewController
//  (see SignUpViewModel.swift's header comment for the full explanation).

import XCTest
@testable import RideTogether

// MARK: - Fakes

private class FakeAuthProvider: AuthProviding {
    var createUserResult: Result<AuthUserResult, Error> = .failure(TestError.notStubbed)
    var signInResult: Result<AuthUserResult, Error> = .failure(TestError.notStubbed)
    private(set) var createUserCallCount = 0
    private(set) var signInCallCount = 0

    func createUser(email _: String, password _: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void) {
        createUserCallCount += 1
        completion(createUserResult)
    }

    func signIn(email _: String, password _: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void) {
        signInCallCount += 1
        completion(signInResult)
    }
}

private enum TestError: Error {
    case notStubbed
}

private func makeViewModel(authProvider: FakeAuthProvider = FakeAuthProvider(), userManager: MockUserManager = MockUserManager()) -> SignUpViewModel {
    SignUpViewModel(authProvider: authProvider, userManager: userManager)
}

// MARK: - Tests

final class SignUpViewModelTests: XCTestCase {
    func testSignUp_emptyEmail_failsWithoutCallingAuthProvider() {
        let authProvider = FakeAuthProvider()
        let sut = makeViewModel(authProvider: authProvider)

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<SignUpFlowResult, Error>?

        sut.signUp(email: "", password: "password123") { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(authProvider.createUserCallCount, 0)
        guard case let .failure(error) = receivedResult else { return XCTFail("expected failure") }
        XCTAssertEqual(error as? SignUpViewModelError, .missingCredentials)
    }

    func testSignUp_newUser_writesUserInfoWithGivenUidAndDefaultName() {
        let authProvider = FakeAuthProvider()
        authProvider.createUserResult = .success(AuthUserResult(uid: "new-uid", isNewUser: true))
        let userManager = MockUserManager()
        let sut = makeViewModel(authProvider: authProvider, userManager: userManager)

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<SignUpFlowResult, Error>?

        sut.signUp(email: "a@b.com", password: "password123", defaultUserName: "破風手") { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        guard case .success(.newUserCreated) = receivedResult else { return XCTFail("expected newUserCreated") }
        XCTAssertEqual(userManager.userInfo.uid, "new-uid")
        XCTAssertEqual(userManager.userInfo.userName, "破風手")
    }

    func testSignUp_returningUser_fetchesAndAssignsUserInfoBeforeReportingSuccess() {
        // Regression test for the race condition found in the original
        // `loginwithFB()`: the ViewController must not be told "done"
        // until userManager.userInfo has actually been updated with the
        // fetched data.
        let authProvider = FakeAuthProvider()
        authProvider.createUserResult = .success(AuthUserResult(uid: "existing-uid", isNewUser: false))
        let userManager = MockUserManager()
        userManager.userInfo.userName = "原本的名字"
        var fetchedInfo = UserInfo()
        fetchedInfo.uid = "existing-uid"
        fetchedInfo.userName = "從資料庫抓到的名字"
        userManager.userInfo = fetchedInfo
        let sut = makeViewModel(authProvider: authProvider, userManager: userManager)

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<SignUpFlowResult, Error>?
        var userNameAtCompletionTime: String?

        sut.signUp(email: "a@b.com", password: "password123") { result in
            // By the time this fires, userManager.userInfo must already
            // reflect the fetch.
            userNameAtCompletionTime = userManager.userInfo.userName
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        guard case .success(.existingUserFetched) = receivedResult else { return XCTFail("expected existingUserFetched") }
        XCTAssertEqual(userNameAtCompletionTime, "從資料庫抓到的名字")
    }

    func testLogIn_newUser_andSignUp_newUser_writeTheSameShapeOfUserInfo() {
        // Regression test for the original inconsistency: sign-up set
        // userName/pictureRef/saveMaps/blockList/totalLength field-by-field,
        // login-as-signup only set userName/blockList. Both should now go
        // through the same path and end up with equivalent UserInfo
        // (aside from uid/userName, which are expected to legitimately
        // differ between the two calls here).
        let signUpAuth = FakeAuthProvider()
        signUpAuth.createUserResult = .success(AuthUserResult(uid: "uid-1", isNewUser: true))
        let signUpUserManager = MockUserManager()
        let signUpSut = makeViewModel(authProvider: signUpAuth, userManager: signUpUserManager)

        let loginAuth = FakeAuthProvider()
        loginAuth.signInResult = .success(AuthUserResult(uid: "uid-2", isNewUser: true))
        let loginUserManager = MockUserManager()
        let loginSut = makeViewModel(authProvider: loginAuth, userManager: loginUserManager)

        let signUpExpectation = expectation(description: "sign up completed")
        signUpSut.signUp(email: "a@b.com", password: "password123") { _ in signUpExpectation.fulfill() }
        wait(for: [signUpExpectation], timeout: 1)

        let loginExpectation = expectation(description: "log in completed")
        loginSut.logIn(email: "c@d.com", password: "password123") { _ in loginExpectation.fulfill() }
        wait(for: [loginExpectation], timeout: 1)

        XCTAssertEqual(signUpUserManager.userInfo.pictureRef, loginUserManager.userInfo.pictureRef)
        XCTAssertEqual(signUpUserManager.userInfo.saveMaps, loginUserManager.userInfo.saveMaps)
        XCTAssertEqual(signUpUserManager.userInfo.blockList, loginUserManager.userInfo.blockList)
        XCTAssertEqual(signUpUserManager.userInfo.totalLength, loginUserManager.userInfo.totalLength)
    }

    func testAuthProvider_failure_isPropagatedAsFailure() {
        let authProvider = FakeAuthProvider()
        authProvider.signInResult = .failure(TestError.notStubbed)
        let sut = makeViewModel(authProvider: authProvider)

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<SignUpFlowResult, Error>?

        sut.logIn(email: "a@b.com", password: "password123") { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        if case .success = receivedResult { XCTFail("expected failure") }
    }
}
