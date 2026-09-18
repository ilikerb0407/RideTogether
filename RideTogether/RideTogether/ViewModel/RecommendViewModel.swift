//
//  RecommendViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  RecommendViewController: fetching the shared-record wall (filtered by
//  the current user's block list), saving one to the user's own saved
//  maps, and blocking the uploader of a record.
//
//  Two things worth noting about what this fixes, beyond testability:
//
//  1. RecommendViewController held its own `lazy var storage`/`dataBase`
//     and wrote directly into the "Savemaps" Firestore collection via
//     `uploadRecordToSavemaps` — bypassing MapsManager entirely even
//     though MapsManager already reads from and deletes from that same
//     collection (`fetchSavemaps`, `deleteDbRecords`). The write now
//     lives on MapsManager as `addToSavemaps`, alongside its existing
//     reads/deletes for the same collection.
//  2. The original block-list filter was
//     `records where userInfo.blockList?.contains(maps.uid) == false`.
//     When `blockList` is `nil` (Firestore documents predating the
//     block-list feature would decode this optional field as nil, not an
//     empty array), `nil?.contains(_) == false` evaluates to
//     `nil == false`, which is `false` — so the `where` clause is false
//     for *every* record, and a user with no block-list data at all would
//     see a completely empty recommend wall instead of seeing every
//     record. Fixed here by treating a nil block list as "nothing
//     blocked" (`blockList ?? []`) rather than letting it silently hide
//     everything.

import Foundation

class RecommendViewModel {
    private(set) var records: [Record] = []

    private let mapsManager: MapsManaging
    private let userManager: UserManaging

    init(
        mapsManager: MapsManaging = MapsManager.shared,
        userManager: UserManaging = UserManager.shared
    ) {
        self.mapsManager = mapsManager
        self.userManager = userManager
    }

    func fetchRecords(completion: @escaping (Result<Void, Error>) -> Void) {
        mapsManager.fetchRecords { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(records):
                let blockList = self.userManager.userInfo.blockList ?? []
                self.records = records.filter { !blockList.contains($0.uid) }
                completion(.success(()))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func saveToSavemaps(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard records.indices.contains(index) else { return }
        let record = records[index]

        mapsManager.addToSavemaps(
            fileName: record.recordName,
            fileRef: record.recordRef,
            userId: userManager.userInfo.uid,
            userPhoto: record.pictureRef ?? "",
            completion: completion
        )
    }

    /// Blocks the uploader of record `index`. Reports
    /// `RecommendViewModelError.cannotBlockSelf` (rather than performing
    /// any write) if the record's uploader is the current user — matches
    /// the original behavior of refusing to let a user block themselves.
    func blockUploader(ofRecordAt index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard records.indices.contains(index) else { return }
        let targetUserId = records[index].uid

        guard targetUserId != userManager.userInfo.uid else {
            completion(.failure(RecommendViewModelError.cannotBlockSelf))
            return
        }

        userManager.blockUser(blockUserId: targetUserId)
        userManager.userInfo.blockList?.append(targetUserId)
        completion(.success(()))
    }
}

enum RecommendViewModelError: Error, Equatable {
    case cannotBlockSelf
}
