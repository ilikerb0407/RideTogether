//
//  GroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseCrashlytics
import FirebaseFirestore
import MJRefresh
import UIKit

internal class GroupViewController: BaseViewController, Reload, UISheetPresentationControllerDelegate, UINavigationControllerDelegate {
    func reload() {
        fetchGroupData()

        tableView.reloadData()
    }

    var createdVC = CreateGroupViewController()

    var groupDetailVC = GroupDetailViewController()

    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    private lazy var cache = [String: UserInfo]() {
        didSet {
            tableView.reloadData()
        }
    }

    private lazy var requests = [Request]() {
        didSet {
            checkRequestsNum()
        }
    }

    private var inActivityGroup = [Group]()

    private var myGroups = [Group]() {
        didSet {
            updateUserHistory()
        }
    }

    private var groupHeaderCell: GroupHeaderCell?

    private var searchGroups = [Group]()

    private var isSearching = false

    private var searchText = "" {
        didSet {
            isSearching = true
        }
    }

    var onlyUserGroup = false

    private var groupInfo: GroupInfoTableViewCell?

    private let header = MJRefreshNormalHeader()

    private let tableView = UITableView()

    func tapAndDismiss() {
        let tap: UITapGestureRecognizer = .init(target: self, action: #selector(dismissKeyBoard))
        tap.delegate = self

        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    @objc
    func dismissKeyBoard() {
        groupHeaderCell?.searchBar.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()

        fetchGroupData()

        setUpHeaderView()

        addRequestListener()

        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))

        tableView.mj_header = header

        createdVC.delegate = self

        tapAndDismiss()

        checkRequestsNum()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroupData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addRequestListener()
    }

    func addRequestListener() {
        GroupManager.shared.addRequestListener { result in

            switch result {
            case let .success(requests):

                var filtedRequests = [Request]()

                for request in requests where self.userInfo.blockList?.contains(request.requestId) == false {
                    filtedRequests.append(request)
                }

                self.requests = filtedRequests

                self.tabBarController?.tabBar.items?[2].badgeValue = "\(requests.count)"
                self.tabBarController?.tabBar.items?[2].badgeColor = .red

            case let .failure(error):

                print("fetchData.failure: \(error)")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.groupChat.rawValue {
            if let chatRoomVC = segue.destination as? GroupDetailViewController {
                if let groupInfo = sender as? Group {
                    chatRoomVC.groupInfo = groupInfo

                    chatRoomVC.cache = cache
                }
            }
        }

        if segue.identifier == SegueIdentifier.requestList.rawValue {
            if let requestVC = segue.destination as? JoinViewController {
                if let requests = sender as? [Request] {
                    requestVC.requests = requests
                }
            }
        }
    }

    func setBuildTeamButton() {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75),
                                         cornerRadius: 25,
                                         title: "揪團",
                                         titleColor: .B5,
                                         titleLabelFont: .systemFont(ofSize: 25, weight: .bold),
                                         pointSize: 70,
                                         xPoint: UIScreen.width * 0.8,
                                         yPoint: UIScreen.height * 0.8)
        button.addTarget(self, action: #selector(creatGroup), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc
    func creatGroup() {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController {
            let navBar = UINavigationController(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [.large(), .medium()]
                    rootVC.delegate = self
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                LKProgressHUD.show(.failure("無法創建活動"))
            }
        }
    }

    func updateUserHistory() {
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: No user is currently logged in")
            return
        }

        var numOfGroups = 0
        var numOfPartners = 0

        for group in myGroups where group.isExpired == true {
            numOfGroups += 1
            numOfPartners += (group.userIds.count - 1) // -1 for self
        }

        UserManager.shared.updateUserGroupRecords(numOfGroups: numOfGroups, numOfPartners: numOfPartners)
    }

    func rearrangeMyGroup(groups: [Group]) {
        var expiredGroup = [Group]()

        var unexpiredGroup = [Group]()

        for group in groups {
            if group.isExpired == true {
                expiredGroup.append(group)

            } else {
                unexpiredGroup.append(group)
            }
        }

        unexpiredGroup.sort { $0.date.seconds < $1.date.seconds }

        expiredGroup.sort { $0.date.seconds < $1.date.seconds }

        myGroups = unexpiredGroup + expiredGroup
    }

    func fetchGroupData() {
        GroupManager.shared.fetchGroups { [self] result in

            switch result {
            case let .success(groups):

                var filteredGroups = [Group]()

                for group in groups where self.userInfo.blockList?.contains(group.hostId) == false {
                    filteredGroups.append(group)
                }

                self.myGroups = filteredGroups.filter { $0.userIds.contains(self.userInfo.uid) }

                self.rearrangeMyGroup(groups: self.myGroups)

                self.inActivityGroup = filteredGroups.filter { $0.isExpired == false }

                self.inActivityGroup.sort { $0.date.seconds < $1.date.seconds }

                for group in filteredGroups {
                    guard self.cache[group.hostId] != nil else {
                        self.fetchUserData(uid: group.hostId)

                        continue
                    }
                }

                tableView.reloadData()

            case let .failure(error):

                print("fetchData.failure: \(error)")

                LKProgressHUD.show(.failure("讀取資料失敗"))
            }
        }
    }

    func fetchUserData(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid, completion: { result in

            switch result {
            case let .success(user):

                self.cache[uid] = user

            case let .failure(error):

                print("fetchData.failure: \(error)")
            }
        })
    }

    // MARK: header

    @objc
    func headerRefresh() {
        fetchGroupData()

        tableView.reloadData()

        self.tableView.mj_header?.endRefreshing()
    }

    func setUpHeaderView() {
        let headerView: GroupHeaderCell = .loadFromNib()

        self.groupHeaderCell = headerView

        headerView.searchBar.delegate = self

        view.addSubview(headerView)

        headerView.searchBar.searchTextField.text = searchText

        headerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),

            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),

            headerView.heightAnchor.constraint(equalToConstant: 80),
        ])

        headerView.resquestsBell.addTarget(self, action: #selector(checkRequestList), for: .touchUpInside)

        headerView.segment.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    @objc
    func checkRequestList(_ sender: UIButton) {
        guard let groupHeaderCell else {
            return
        }

        if !requests.isEmpty {
            performSegue(withIdentifier: SegueIdentifier.requestList.rawValue, sender: requests)

        } else {
            groupHeaderCell.resquestsBell.shake()
        }
    }

    func checkRequestsNum() {
        guard let groupHeaderCell else {
            return
        }

        if requests.isEmpty {
        } else {
            groupHeaderCell.resquestsBell.shake()
        }
    }

    @objc
    func segmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            onlyUserGroup = false

        case 1:
            onlyUserGroup = true

        default:
            return
        }
        tableView.reloadData()
    }

    func setUpTableView() {

        tableView.backgroundColor = .clear

        tableView.delegate = self

        tableView.dataSource = self

        tableView.registerCellWithNib(identifier: GroupInfoTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        setBuildTeamButton()

        tableView.separatorStyle = .none

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    // 查詢團名
    func filtGroupBySearchName(groups: [Group]) -> [Group] {
        let filteredGroups = groups.filter { group in
            group.routeName.lowercased().prefix(searchText.count) == searchText.lowercased()
        }

        return filteredGroups
    }
}

// MARK: - SearchBar Delegate -

extension GroupViewController: UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0

        UIView.animate(
            withDuration: 0.4,
            delay: 0.03 * Double(indexPath.row),
            animations: {
                cell.alpha = 1
            }
        )
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        200
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        var sender = [Group]()

        if isSearching {
            sender = searchGroups

        } else {
            if onlyUserGroup {
                sender = myGroups

            } else {
                sender = inActivityGroup
            }
        }
        performSegue(withIdentifier: SegueIdentifier.groupChat.rawValue, sender: sender[indexPath.row])
    }
}

// MARK: - TableView Data Source -

extension GroupViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if isSearching {
            return searchGroups.count

        } else {
            if onlyUserGroup {
                return myGroups.count

            } else {
                return inActivityGroup.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: GroupInfoTableViewCell = tableView.dequeueCell(for: indexPath)

        var group = Group()

        if isSearching {
            group = searchGroups[indexPath.row]

        } else {
            if onlyUserGroup {
                group = myGroups[indexPath.row]

            } else {
                group = inActivityGroup[indexPath.row]
            }
        }

        cell.setUpCell(group: group, hostname: cache[group.hostId]?.userName ?? "使用者")

        return cell
    }
}

extension GroupViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText

        if onlyUserGroup {
            searchGroups = filtGroupBySearchName(groups: myGroups)
        } else {
            searchGroups = filtGroupBySearchName(groups: inActivityGroup)
        }
        tableView.reloadData()
        isSearching = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
