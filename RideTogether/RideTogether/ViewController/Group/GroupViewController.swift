//
//  GroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import UIKit
import Firebase
import MJRefresh
import MASegmentedControl
import FirebaseAuth
import FirebaseFirestore
import AVFoundation
import FirebaseCrashlytics

class GroupViewController: BaseViewController, Reload, UISheetPresentationControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Outlets

    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }

    // MARK: - Properties

    var table: UITableView?
    var VC = CreateGroupViewController()
    var onlyUserGroup = false

    private var userInfo: UserInfo { UserManager.shared.userInfo }
    private var groupInfo: GroupInfo?
    private let header = MJRefreshNormalHeader()

    private lazy var cache = [String: UserInfo]() {
        didSet { tableView.reloadData() }
    }

    private lazy var requests = [Request]() {
        didSet { checkRequestsNum() }
    }

    private var inActivityGroup = [Group]()

    private var myGroups = [Group]() {
        didSet { updateUserHistory() }
    }

    private var groupHeaderCell: GroupHeaderCell?
    private var requestListenerRegistration: ListenerRegistration?

    private var searchGroups = [Group]()
    private var isSearching = false
    private var searchText = "" {
        didSet { isSearching = true }
    }

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    // MARK: - Lifecycle

    deinit {
        requestListenerRegistration?.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchGroupData()
        setUpHeaderView()
        addRequestListener()
        setUpTableView()

        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))
        tableView.mj_header = header
        table?.delegate = self
        VC.delegate = self

        tapAndDismiss()
        checkRequestsNum()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Listener 已在 viewDidLoad 建立，不需重複呼叫
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.groupChat.rawValue,
           let chatRoomVC = segue.destination as? ChatRoomViewController,
           let groupInfo = sender as? Group {
            chatRoomVC.groupInfo = groupInfo
            chatRoomVC.cache = cache
        }

        if segue.identifier == SegueIdentifier.requestList.rawValue,
           let requestVC = segue.destination as? JoinViewController,
           let requests = sender as? [Request] {
            requestVC.requests = requests
        }
    }

    // MARK: - Reload Protocol

    func reload() {
        fetchGroupData()
        tableView.reloadData()
    }
}

// MARK: - Data

extension GroupViewController {

    func fetchGroupData() {
        GroupManager.shared.fetchGroups { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let groups):
                let filtered = groups.filter { self.userInfo.blockList?.contains($0.hostId) == false }
                self.myGroups = filtered.filter { $0.userIds.contains(self.userInfo.uid) }
                self.rearrangeMyGroup(groups: self.myGroups)
                self.inActivityGroup = filtered.filter { $0.isExpired == false }
                    .sorted { $0.date.seconds < $1.date.seconds }
                filtered.forEach { group in
                    guard self.cache[group.hostId] == nil else { return }
                    self.fetchUserData(uid: group.hostId)
                }

            case .failure(let error):
                print("fetchData.failure: \(error)")
                LKProgressHUD.showFailure(text: "讀取資料失敗")
            }
        }
    }

    func fetchUserData(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            switch result {
            case .success(let user):
                self?.cache[uid] = user
            case .failure(let error):
                print("fetchData.failure: \(error)")
            }
        }
    }

    func updateUserHistory() {
        let expired = myGroups.filter { $0.isExpired == true }
        let numOfGroups = expired.count
        let numOfPartners = expired.reduce(0) { $0 + ($1.userIds.count - 1) }
        UserManager.shared.updateUserGroupRecords(numOfGroups: numOfGroups, numOfPartners: numOfPartners)
    }

    func rearrangeMyGroup(groups: [Group]) {
        let unexpired = groups.filter { !$0.isExpired! }.sorted { $0.date.seconds < $1.date.seconds }
        let expired   = groups.filter {  $0.isExpired! }.sorted { $0.date.seconds < $1.date.seconds }
        myGroups = unexpired + expired
    }
}

// MARK: - Listener

extension GroupViewController {

    func addRequestListener() {
        requestListenerRegistration = GroupManager.shared.addRequestListener { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let requests):
                self.requests = requests.filter {
                    self.userInfo.blockList?.contains($0.requestId) == false
                }
                self.tabBarController?.tabBar.items?[2].badgeValue = "\(self.requests.count)"
                self.tabBarController?.tabBar.items?[2].badgeColor = .red

            case .failure(let error):
                print("fetchData.failure: \(error)")
            }
        }
    }
}

// MARK: - UI Setup

extension GroupViewController {

    func setUpTableView() {
        tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.registerCellWithNib(identifier: GroupInfo.identifier, bundle: nil)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        setBuildTeamButton()

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func setUpHeaderView() {
        let headerView: GroupHeaderCell = .loadFromNib()
        groupHeaderCell = headerView
        headerView.searchBar.delegate = self
        headerView.searchBar.searchTextField.text = searchText
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80)
        ])

        headerView.resquestsBell.addTarget(self, action: #selector(checkRequestList), for: .touchUpInside)
        headerView.segment.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    func setBuildTeamButton() {
        let button = CreatGroupButton()
        button.addTarget(self, action: #selector(creatGroup), for: .touchUpInside)
        view.addSubview(button)
    }

    func checkRequestsNum() {
        guard let groupHeaderCell = groupHeaderCell, requests.count > 0 else { return }
        groupHeaderCell.resquestsBell.shake()
    }
}

// MARK: - Actions

extension GroupViewController {

    @objc func creatGroup() {
        guard let rootVC = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController else { return }
        let navBar = UINavigationController(rootViewController: rootVC)
        if #available(iOS 15.0, *), let sheet = navBar.sheetPresentationController {
            sheet.detents = [.large(), .medium()]
            rootVC.delegate = self
            navigationController?.present(navBar, animated: true)
        } else {
            LKProgressHUD.showFailure(text: "無法創建活動")
        }
    }

    @objc func checkRequestList(_ sender: UIButton) {
        guard requests.count > 0 else { return }
        performSegue(withIdentifier: SegueIdentifier.requestList.rawValue, sender: requests)
    }

    @objc func headerRefresh() {
        fetchGroupData()
        tableView.reloadData()
        tableView.mj_header?.endRefreshing()
    }

    @objc func segmentValueChanged(_ sender: UISegmentedControl) {
        onlyUserGroup = sender.selectedSegmentIndex == 1
        tableView.reloadData()
    }

    func tapAndDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyBoard))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyBoard() {
        groupHeaderCell?.searchBar.resignFirstResponder()
    }

    private func currentGroups() -> [Group] {
        if isSearching { return searchGroups }
        return onlyUserGroup ? myGroups : inActivityGroup
    }

    private func filtGroupBySearchName(groups: [Group]) -> [Group] {
        groups.filter {
            $0.routeName.lowercased().prefix(searchText.count) == searchText.lowercased()
        }
    }
}

// MARK: - TableView Delegate

extension GroupViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.03 * Double(indexPath.row)) {
            cell.alpha = 1
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let groups = currentGroups()
        performSegue(withIdentifier: SegueIdentifier.groupChat.rawValue, sender: groups[indexPath.row])
    }
}

// MARK: - TableView DataSource

extension GroupViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentGroups().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: GroupInfo = tableView.dequeueCell(for: indexPath)
        let group = currentGroups()[indexPath.row]
        cell.setUpCell(group: group, hostname: cache[group.hostId]?.userName ?? "使用者")
        return cell
    }
}

// MARK: - SearchBar Delegate

extension GroupViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        let source = onlyUserGroup ? myGroups : inActivityGroup
        searchGroups = filtGroupBySearchName(groups: source)
        isSearching = true
        tableView.reloadData()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
