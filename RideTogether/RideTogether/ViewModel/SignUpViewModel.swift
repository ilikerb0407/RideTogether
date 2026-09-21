//
//  SignUpViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  SignUpViewController: creating a new Firebase Auth account, signing in
//  an existing one, and the "new user vs returning user" branching that
//  decides whether to write a fresh UserInfo document or fetch the
//  existing one.
//
//  Several real bugs were found and fixed while consolidating this:
//
//  1. The original `loginwithFB()` method (despite its name, this is
//     plain email/password sign-in — there's no actual Facebook login
//     anywhere in this file; the name has been fixed to `logIn` on the
//     ViewController) had a race condition in its "returning user"
//     branch: it called `UserManager.shared.fetchUserInfo` and then,
//     immediately after — NOT inside that fetch's completion — built and
//     presented the TabBarController. The home screen could appear before
//     `UserManager.shared.userInfo` had actually been updated with the
//     fetched data. The equivalent branch in the original `signUp()`
//     method did this correctly (present only inside the fetch's
//     completion). This ViewModel has exactly one implementation of
//     "returning user" handling, shared by both flows, so this class of
//     bug can't recur by the two flows silently drifting apart.
//  2. The two flows initialized a new user's UserInfo differently: sign-up
//     set `userName`, `pictureRef`, `saveMaps`, `blockList`, and
//     `totalLength` field-by-field; login-as-signup only set `userName`
//     and `blockList`. They happened to agree in practice because
//     `UserInfo.init()`'s defaults already match what sign-up set
//     explicitly, but that was incidental, not guaranteed — a future
//     change to one flow's field list could silently stop matching the
//     other. Now both go through one path that starts from
//     `UserInfo()`'s defaults and only overrides `uid`/`userName`.
//  3. The original sign-up success path wrapped showing a "congratulations"
//     alert in a `DispatchSemaphore(value: 1)` + `wait()`/`signal()` pair
//     that did nothing (nothing else ever contends for that semaphore) —
//     dead complexity around what's just `DispatchQueue.main.async`.
//     Removed; the ViewController now just dispatches its own UI
//     reaction to main after the ViewModel reports success.

import FirebaseAuth
import Foundation

// MARK: - AuthProviding

/// Abstraction over Firebase Auth's create/sign-in calls, so
/// `SignUpViewModel` can be tested without a real network call to
/// Firebase Auth.
protocol AuthProviding: AnyObject {
    func createUser(email: String, password: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void)
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void)
}

struct AuthUserResult {
    let uid: String
    let isNewUser: Bool
}

enum AuthProvidingError: Error {
    /// Firebase Auth reported success but didn't include the user/
    /// isNewUser data this app needs to proceed.
    case missingUserData
}

class FirebaseAuthProvider: AuthProviding {
    func createUser(email: String, password: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            Self.handle(authResult: authResult, error: error, completion: completion)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<AuthUserResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            Self.handle(authResult: authResult, error: error, completion: completion)
        }
    }

    private static func handle(authResult: AuthDataResult?, error: Error?, completion: @escaping (Result<AuthUserResult, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let authResult = authResult, let isNewUser = authResult.additionalUserInfo?.isNewUser else {
            completion(.failure(AuthProvidingError.missingUserData))
            return
        }
        completion(.success(AuthUserResult(uid: authResult.user.uid, isNewUser: isNewUser)))
    }
}

// MARK: - SignUpViewModel

enum SignUpFlowResult {
    case newUserCreated
    case existingUserFetched
}

enum SignUpViewModelError: Error, Equatable {
    case missingCredentials
}

class SignUpViewModel {
    private let authProvider: AuthProviding
    private let userManager: UserManaging

    init(
        authProvider: AuthProviding = FirebaseAuthProvider(),
        userManager: UserManaging = UserManager.shared
    ) {
        self.authProvider = authProvider
        self.userManager = userManager
    }

    /// Creates a new Firebase Auth account. `defaultUserName` is only
    /// used if this turns out to be a genuinely new user.
    func signUp(email: String?, password: String?, defaultUserName: String = "破風手", completion: @escaping (Result<SignUpFlowResult, Error>) -> Void) {
        guard let email = email, !email.isEmpty, let password = password, !password.isEmpty else {
            completion(.failure(SignUpViewModelError.missingCredentials))
            return
        }

        authProvider.createUser(email: email, password: password) { [weak self] result in
            self?.handleAuthResult(result, defaultUserName: defaultUserName, completion: completion)
        }
    }

    /// Signs in with an existing (or, if Firebase reports it as new,
    /// freshly-created-on-the-spot) email/password account.
    func logIn(email: String?, password: String?, defaultUserName: String = "新使用者", completion: @escaping (Result<SignUpFlowResult, Error>) -> Void) {
        guard let email = email, !email.isEmpty, let password = password, !password.isEmpty else {
            completion(.failure(SignUpViewModelError.missingCredentials))
            return
        }

        authProvider.signIn(email: email, password: password) { [weak self] result in
            self?.handleAuthResult(result, defaultUserName: defaultUserName, completion: completion)
        }
    }

    private func handleAuthResult(_ result: Result<AuthUserResult, Error>, defaultUserName: String, completion: @escaping (Result<SignUpFlowResult, Error>) -> Void) {
        switch result {
        case let .failure(error):
            completion(.failure(error))

        case let .success(authUser):
            if authUser.isNewUser {
                var newUserInfo = UserInfo()
                newUserInfo.uid = authUser.uid
                newUserInfo.userName = defaultUserName

                userManager.signUpUserInfo(userInfo: newUserInfo) { result in
                    switch result {
                    case .success:
                        completion(.success(.newUserCreated))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            } else {
                // This single path — fetch, THEN update userManager.userInfo,
                // THEN report success — is what fixes the race condition
                // described at the top of this file: the ViewController
                // only reacts (presenting the tab bar) once this
                // completion fires, never before.
                userManager.fetchUserInfo(uid: authUser.uid) { [weak self] result in
                    switch result {
                    case let .success(userInfo):
                        self?.userManager.userInfo = userInfo
                        completion(.success(.existingUserFetched))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
