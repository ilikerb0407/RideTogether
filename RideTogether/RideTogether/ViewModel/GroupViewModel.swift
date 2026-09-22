//
//  GroupViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  GroupViewController: fetching groups (split into "my groups" and
//  "active groups", both filtered by block list), fetching each group
//  host's cached user info, listening for join requests, and computing
//  the user's group history stats.
//
//  Three real bugs were found and fixed while extracting this:
//
//  1. Two separate places filtered by block list using
//     `userInfo.blockList?.contains(id) == false`. When `blockList` is
//     nil (a Firestore document predating this field would decode it as
//     nil, not an empty array), `nil?.contains(_) == false` evaluates to
//     `nil == false`, which is `false` for every item — so the entire
//     list (every group, every join request) would be filtered out
//     instead of showing everything. This is the exact same bug class
//     already fixed once in RecommendViewModel; fixed here the same way,
//     by treating a nil block list as "nothing blocked"
//     (`blockList ?? []`).
//  2. `rearrangeMyGroup` did `groups.filter { !$0.isExpired! }` — a force
//     unwrap of an optional Bool that crashes if `isExpired` is ever nil.
//     Replaced with `$0.isExpired != true`, which treats a nil/unknown
//     expiry status the same way as "not expired" rather than crashing —
//     consistent with how `inActivityGroup`'s filter is written below.
//  3. `userInfo`, `fetchUserData`, and `updateUserHistory` all called
//     `UserManager.shared` directly, inconsistent with `groupManager`
//     (already injected). Both dependencies are now injected the same
//     way, matching every other ViewModel in this project.

import FirebaseFirestore
import Foundation

class GroupViewModel {
    private(set) var myGroups: [Group] = []
    private(set) var inActivityGroup: [Group] = []
    private(set) var requests: [Request] = []
    private(set) var hostCache: [String: UserInfo] = [:]

    private(set) var searchGroups: [Group] = []
    private(set) var isSearching = false
    private(set) var searchText = ""
    var onlyUserGroup = false

    /// Fires whenever `myGroups`/`inActivityGroup` change, after any
    /// newly-needed host user data has also finished loading — so the
    /// ViewController can just reload its table view once per fetch
    /// rather than juggling two separate callbacks.
    var onGroupsUpdated: (() -> Void)?

    /// Fires whenever the live join-request listener delivers an update.
    var onRequestsUpdated: (() -> Void)?

    private let groupManager: GroupManaging
    private let userManager: UserManaging
    private var requestListenerRegistration: ListenerRegistration?

    init(
        groupManager: GroupManaging = GroupManager.shared,
        userManager: UserManaging = UserManager.shared
    ) {
        self.groupManager = groupManager
        self.userManager = userManager
    }

    deinit {
        requestListenerRegistration?.remove()
    }

    /// The list the table view should currently show: search results
    /// while searching, otherwise "my groups" or "active groups"
    /// depending on `onlyUserGroup`.
    func currentGroups() -> [Group] {
        if isSearching { return searchGroups }
        return onlyUserGroup ? myGroups : inActivityGroup
    }

    func fetchGroupData(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        groupManager.fetchGroups { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(groups):
                let blockList = self.userManager.userInfo.blockList ?? []
                let filtered = groups.filter { !blockList.contains($0.hostId) }

                let mine = filtered.filter { $0.userIds.contains(self.userManager.userInfo.uid) }
                self.myGroups = self.rearranged(mine)

                self.inActivityGroup = filtered
                    .filter { $0.isExpired != true }
                    .sorted { $0.date.seconds < $1.date.seconds }

                self.updateUserHistory()

                let uidsNeedingFetch = Set(filtered.map(\.hostId)).subtracting(self.hostCache.keys)
                self.fetchHostData(uids: Array(uidsNeedingFetch)) {
                    self.onGroupsUpdated?()
                    completion(.success(()))
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Sorts unexpired groups before expired ones, each internally
    /// sorted by date — matches the original `rearrangeMyGroup`'s
    /// ordering, minus the force unwrap that used to crash on a nil
    /// `isExpired`.
    private func rearranged(_ groups: [Group]) -> [Group] {
        let unexpired = groups.filter { $0.isExpired != true }.sorted { $0.date.seconds < $1.date.seconds }
        let expired = groups.filter { $0.isExpired == true }.sorted { $0.date.seconds < $1.date.seconds }
        return unexpired + expired
    }

    private func fetchHostData(uids: [String], completion: @escaping () -> Void) {
        guard !uids.isEmpty else {
            completion()
            return
        }

        let group = DispatchGroup()

        for uid in uids {
            group.enter()
            userManager.fetchUserInfo(uid: uid) { [weak self] result in
                if case let .success(user) = result {
                    self?.hostCache[uid] = user
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    private func updateUserHistory() {
        let expired = myGroups.filter { $0.isExpired == true }
        let numOfGroups = expired.count
        let numOfPartners = expired.reduce(0) { $0 + ($1.userIds.count - 1) }
        userManager.updateUserGroupRecords(numOfGroups: numOfGroups, numOfPartners: numOfPartners)
    }

    func addRequestListener() {
        requestListenerRegistration = groupManager.addRequestListener { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(requests):
                let blockList = self.userManager.userInfo.blockList ?? []
                self.requests = requests.filter { !blockList.contains($0.requestId) }
                self.onRequestsUpdated?()

            case .failure:
                break
            }
        }
    }

    func updateSearch(text: String) {
        searchText = text
        isSearching = true
        let source = onlyUserGroup ? myGroups : inActivityGroup
        searchGroups = source.filter {
            $0.routeName.lowercased().prefix(text.count) == text.lowercased()
        }
    }

    func endSearch() {
        isSearching = false
    }
}
