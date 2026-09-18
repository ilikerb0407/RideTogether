//
//  ManagerProtocols.swift
//  RideTogether
//
//  Protocol abstractions over the app's Manager singletons.
//
//  Why this file exists: every Manager (UserManager, GroupManager,
//  RecordManager, BikeManager, MapsManager, WeatherManager) was previously a
//  concrete class with a hardcoded `.shared` singleton, and ViewControllers
//  called `XxxManager.shared.method()` directly. That made it impossible to
//  unit test any ViewController logic without hitting real Firebase/network
//  calls, because there was no seam to substitute a fake implementation.
//
//  These protocols declare only the methods that are actually called from
//  outside each Manager today (verified against the codebase). The Manager
//  classes now conform to them (see the `extension XxxManager: XxxManaging`
//  in each Manager's own file), and ViewControllers can depend on the
//  protocol type instead of the concrete class, injected via `init` or a
//  mutable property defaulting to `.shared`. This is a non-breaking change:
//  existing call sites that still say `UserManager.shared.foo()` keep
//  working exactly as before.

import FirebaseFirestore
import Foundation
import CoreLocation

// MARK: - UserManaging

protocol UserManaging: AnyObject {
    var userId: String? { get }
    var userInfo: UserInfo { get set }

    func deleteUserInfo(uid: String)
    func deleteUserFromGroup(uid: String)
    func deleteUserRequests(uid: String)
    func deleteUserSharemaps(uid: String)
    func signUpUserInfo(userInfo: UserInfo, completion: @escaping (Result<String, Error>) -> Void)
    func fetchUserInfo(uid: String, completion: @escaping (Result<UserInfo, Error>) -> Void)
    func uploadUserPicture(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void)
    func updateImageToDb(fileURL: URL)
    func updateUserName(name: String)
    func updateUserGroupRecords(numOfGroups: Int, numOfPartners: Int)
    func updateUserTrackLength(length: Double)
    func blockUser(blockUserId: String)
}

// MARK: - GroupManaging

protocol GroupManaging: AnyObject {
    var userId: String { get }

    func buildTeam(group: inout Group, completion: (Result<String, Error>) -> Void)
    func fetchGroups(completion: @escaping (Result<[Group], Error>) -> Void)
    func requestListener(completion: @escaping (Result<[Request], Error>) -> Void)
    func updateTeam(group: Group, completion: (Result<String, Error>) -> Void)
    func sendRequest(request: Request, completion: (Result<String, Error>) -> Void)
    func leaveGroup(groupId: String, completion: @escaping (Result<String, Error>) -> Void)
    @discardableResult
    func addRequestListener(completion: @escaping (Result<[Request], Error>) -> Void) -> ListenerRegistration
    func addUserToGroup(groupId: String, userId: String, completion: @escaping (Result<String, Error>) -> Void)
    func removeRequest(groupId: String, userId: String, completion: @escaping (Result<String, Error>) -> Void)
}

// MARK: - RecordManaging

protocol RecordManaging: AnyObject {
    var userId: String { get }
    var userPhoto: String { get }

    func uploadRecord(fileName: String, fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void)
    func uploadRecordToDb(fileName: String, fileURL: URL)
    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void)
    func fetchOneRecord(completion: @escaping (Result<Record, Error>) -> Void)
    func deleteStorageRecords(fileName: String, completion: @escaping (Result<String, Error>) -> Void)
    func deleteDbRecords(fileName: String)
}

// MARK: - BikeManaging

protocol BikeManaging: AnyObject {
    func getBikeAPI(completion: @escaping ([Bike]) -> Void)
}

// MARK: - MapsManaging

protocol MapsManaging: AnyObject {
    var userId: String { get }
    var savemaps: [String] { get }

    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void)
    func fetchRoutes(completion: @escaping (Result<[Route], Error>) -> Void)
    func fetchSavemaps(completion: @escaping (Result<[Record], Error>) -> Void)
    func deleteDbRecords(recordId: String, completion: @escaping (Result<String, Error>) -> Void)
}

// MARK: - WeatherManaging

protocol WeatherManaging: AnyObject {
    func getGroupAPI(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (ResponseBody) -> Void)
}
