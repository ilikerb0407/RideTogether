//
//  TracksViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  TracksViewController: fetching the user's ride records, deleting one,
//  and the multi-step "share a record" flow (get a Storage download URL,
//  write a shared-record document, write a "popular route" document, and
//  parse the shared GPX file to compute its total distance).
//
//  A few things worth noting about what this fixes, beyond testability:
//
//  1. TracksViewController held its own `lazy var storage`/`dataBase`
//     (separate Storage/Firestore instances from the ones RecordManager
//     and MapsManager already own), and wrote directly into the
//     "Sharemaps" and "Routes" Firestore collections — collections that
//     conceptually belong to MapsManager's domain (MapsManager already
//     *reads* from both, via `fetchRecords`/`fetchRoutes`), without going
//     through any Manager at all. `RecordSharingService` below is the
//     single place that now owns writing to those two collections,
//     consistent with how every other Firestore access in this project
//     goes through a dedicated Manager/Service rather than ad-hoc
//     `Firestore.firestore()` calls scattered across ViewControllers.
//  2. The original `uploadRecordToDb`/`uploadRecordToPopular` methods
//     caught Firestore write errors, printed them, and showed a failure
//     HUD — but had no way to tell their caller the write failed (no
//     completion handler, no return value). A share that silently fails
//     to write one of the two documents looked identical to a fully
//     successful share. `RecordSharing`'s methods report success/failure
//     properly, and `TracksViewModel.shareRecord` waits for both writes
//     and reports a combined result.

import CoreGPX
import FirebaseFirestore
import FirebaseStorage
import Foundation

// MARK: - RecordSharing

/// Everything involved in turning one of the user's private ride records
/// into a shared, discoverable route: recording that it was shared, and
/// adding it to the browsable "popular routes" list. (Looking up the
/// record's Storage download URL is a separate concern — see
/// `RecordSharingDownloading` below — kept apart because it's a different
/// dependency, Storage rather than Firestore, and tests commonly want to
/// stub the two independently.)
protocol RecordSharing: AnyObject {
    func addToSharedRecords(fileName: String, fileURL: URL, userId: String, userPhoto: String, completion: @escaping (Result<Void, Error>) -> Void)
    func addToPopularRoutes(fileName: String, fileURL: URL, userId: String, userName: String, userPhoto: String, routeLength: String, completion: @escaping (Result<Void, Error>) -> Void)
}

class RecordSharingService: RecordSharing {
    private lazy var dataBase = Firestore.firestore()

    private let sharedRecordsCollection = Collection.sharedmaps.rawValue
    private let routeCollection = Collection.routes.rawValue

    func addToSharedRecords(fileName: String, fileURL: URL, userId: String, userPhoto: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let document = dataBase.collection(sharedRecordsCollection).document()

        var record = Record()
        record.uid = userId
        record.recordId = document.documentID
        record.recordName = fileName
        record.recordRef = fileURL.absoluteString
        record.pictureRef = userPhoto
        record.routeTypes = 0

        do {
            try document.setData(from: record)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func addToPopularRoutes(fileName: String, fileURL: URL, userId: String, userName: String, userPhoto: String, routeLength: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let document = dataBase.collection(routeCollection).document()

        var route = RouteModel()
        route.uid = userId
        route.routeId = document.documentID
        route.routeName = fileName
        route.routeMap = fileURL.absoluteString
        route.routeInfo = "\(userName) 分享了路線"
        route.pictureRef = userPhoto
        route.routeLength = routeLength
        route.routeTypes = 0

        do {
            try document.setData(from: route)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - GPXLengthCalculating

/// Abstraction over parsing a GPX file (local or remote) with CoreGPX to
/// compute its total track length, so `TracksViewModel` can be tested
/// without downloading/parsing a real file.
protocol GPXLengthCalculating {
    func totalLength(ofGPXAt url: URL) -> Double?
}

class CoreGPXLengthCalculator: GPXLengthCalculating {
    func totalLength(ofGPXAt url: URL) -> Double? {
        GPXParser(withURL: url)?.parsedData()?.tracksLength
    }
}

// MARK: - TracksViewModel

class TracksViewModel {
    private(set) var records: [Record] = []

    private let recordManager: RecordManaging
    private let recordSharingStorage: RecordSharingDownloading
    private let recordSharing: RecordSharing
    private let gpxLengthCalculator: GPXLengthCalculating
    private let userManager: UserManaging

    init(
        recordManager: RecordManaging = RecordManager.shared,
        recordSharingStorage: RecordSharingDownloading = FirebaseRecordSharingDownloader(),
        recordSharing: RecordSharing = RecordSharingService(),
        gpxLengthCalculator: GPXLengthCalculating = CoreGPXLengthCalculator(),
        userManager: UserManaging = UserManager.shared
    ) {
        self.recordManager = recordManager
        self.recordSharingStorage = recordSharingStorage
        self.recordSharing = recordSharing
        self.gpxLengthCalculator = gpxLengthCalculator
        self.userManager = userManager
    }

    func fetchRecords(completion: @escaping (Result<Void, Error>) -> Void) {
        recordManager.fetchRecords { [weak self] result in
            switch result {
            case let .success(records):
                self?.records = records
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func deleteRecord(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard records.indices.contains(index) else { return }
        let fileName = records[index].recordName

        recordManager.deleteStorageRecords(fileName: fileName) { [weak self] result in
            switch result {
            case .success:
                self?.records.remove(at: index)
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Shares record `index`: fetches its download URL, then writes both
    /// the "shared record" document and the "popular route" document
    /// (computing the route's total distance along the way), and reports
    /// success only once every step has actually succeeded.
    func shareRecord(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard records.indices.contains(index) else { return }
        let record = records[index]
        let userId = userManager.userInfo.uid
        let userPhoto = userManager.userInfo.pictureRef ?? ""
        let userName = userManager.userInfo.userName ?? ""

        recordSharingStorage.downloadURL(userId: userId, fileName: record.recordName) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))

            case let .success(url):
                let length = self.gpxLengthCalculator.totalLength(ofGPXAt: url)
                let routeLength = "距離 : \(length?.toDistance() ?? "未知")"

                let group = DispatchGroup()
                var firstError: Error?

                group.enter()
                self.recordSharing.addToSharedRecords(fileName: record.recordName, fileURL: url, userId: userId, userPhoto: userPhoto) { result in
                    if case let .failure(error) = result { firstError = firstError ?? error }
                    group.leave()
                }

                group.enter()
                self.recordSharing.addToPopularRoutes(fileName: record.recordName, fileURL: url, userId: userId, userName: userName, userPhoto: userPhoto, routeLength: routeLength) { result in
                    if case let .failure(error) = result { firstError = firstError ?? error }
                    group.leave()
                }

                group.notify(queue: .main) {
                    if let error = firstError {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
}

// MARK: - RecordSharingDownloading

/// Abstraction over the Storage download-URL lookup used when sharing a
/// record, kept separate from `RecordSharing` (the Firestore writes)
/// since it's a different dependency (Storage, not Firestore) and tests
/// commonly want to stub them independently.
protocol RecordSharingDownloading: AnyObject {
    func downloadURL(userId: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void)
}

class FirebaseRecordSharingDownloader: RecordSharingDownloading {
    private lazy var storage = Storage.storage()
    private lazy var storageRef = storage.reference()

    func downloadURL(userId: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let recordRef = storageRef.child("records").child(userId)
        let spaceRef = recordRef.child(fileName)

        spaceRef.downloadURL { result in
            completion(result)
        }
    }
}
