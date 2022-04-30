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

class GroupViewController: BaseViewController, Reload, UISheetPresentationControllerDelegate, UINavigationControllerDelegate {
    
    func reload() {
        
        fetchGroupData()
        
    }
    
    var table: UITableView?
    
    var VC = CreateGroupViewController()
    
    
    private lazy var cache = [String: UserInfo]() {
        
        didSet {
            tableView.reloadData()
        }
    }
    private lazy var requests = [Request]()
   

    
    // MARK: Class Properties
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
    private var inActivityGroup = [Group]()
    
    private var myGroups = [Group]() {
        
        didSet {
            updateUserHistory()
        }
    }
    
    private var groupHeaderCell: GroupHeaderCell?
    
    // Search Bar 查詢 Groups
    private var searchGroups = [Group]()
    
    private var isSearching = false
    
    private var searchText = "" {
        
        didSet {
            isSearching = true
        }
       
    }
    
    var onlyUserGroup = false
    
    private var groupInfo: GroupInfo?
    
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchGroupData()
        
        setUpHeaderView()
        
        addRequestListener()
        
        setUpTableView()
        
        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))
        
        tableView.mj_header = header
        
        view.backgroundColor = .U2
        
        table?.delegate = self
        
        VC.delegate = self
        
        
    }
    
    func addRequestListener() {
        
        GroupManager.shared.addRequestListener { result in
            
            switch result {
                
            case .success(let requests):
                
                var filtedRequests = [Request]()
                
                for request in requests where self.userInfo.blockList?.contains(request.requestId) == false {
                    
                    filtedRequests.append(request)
                }
                
                self.requests = filtedRequests
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SegueIdentifier.groupChat.rawValue {
            if let chatRoomVC = segue.destination as? ChatRoomViewController {
                
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
        
        let button = CreatGroupButton()
        button.addTarget(self, action:  #selector(creatGroup), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func creatGroup() {
        
        
//       performSegue(withIdentifier: SegueIdentifier.buildTeam.rawValue, sender: nil)
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if let presentVc = navBar.sheetPresentationController {
                presentVc.detents = [.medium()]
                rootVC.delegate = self
            self.navigationController?.present(navBar, animated: true, completion: .none)
        }
        }
    }
    // MARK: 確定時間有沒有過期
    
    func updateUserHistory() {
        
        var numOfGroups = 0
        
        var numOfPartners = 0
        
        myGroups.forEach { group in
            
            if group.isExpired == true {
                
                numOfGroups += 1
                
                numOfPartners += (group.userIds.count - 1) // -1 for self
            }
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
       
        unexpiredGroup.sort { $0.date.seconds > $1.date.seconds }
        
        expiredGroup.sort { $0.date.seconds > $1.date.seconds }
        
        myGroups =  unexpiredGroup + expiredGroup
    }
    
    // MARK: 抓資料
    

    func fetchGroupData() {
        
        GroupManager.shared.fetchGroups { [self] result in
            
            switch result {
                
            case .success(let groups):
                
                var filteredGroups = [Group]()
                
                for group in groups where self.userInfo.blockList?.contains(group.hostId) == false {

                    filteredGroups.append(group)
                }
                
                self.myGroups = filteredGroups.filter {
                    $0.userIds.contains(self.userInfo.uid)
                }
                
                self.inActivityGroup = filteredGroups.filter { $0.isExpired == false }
                
                self.rearrangeMyGroup(groups: self.myGroups)
                
                filteredGroups.forEach { group in
                    
                    guard self.cache[group.hostId] != nil else {
                        
                        self.fetchUserData(uid: group.hostId)
                        
                        self.table?.reloadData()
                        
                        return
                    }
                }
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
    }
    
    
    func fetchUserData(uid: String) {
        
        UserManager.shared.fetchUserInfo(uid: uid, completion: { result in
            
            switch result {
                
            case .success(let user):
                
                self.cache[uid] = user
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        })
    }
    

    
    // MARK: header
    
    @objc func headerRefresh() {
        
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
            
            headerView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
          headerView.resquestsBell.addTarget(self, action: #selector(checkRequestList), for: .touchUpInside)
        
          headerView.segment.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
        
    }
    
    @objc func checkRequestList(_ sender: UIButton) {
        
        if requests.count != 0 {
            
            performSegue(withIdentifier: SegueIdentifier.requestList.rawValue, sender: requests)
            
        } else {
            
            groupHeaderCell?.resquestsBell.shake()
        }
    }
    
    func checkRequestsNum() {
        
        guard let groupHeaderCell = groupHeaderCell else { return }
        
        if requests.count == 0 {
            

        } else {
            
            groupHeaderCell.resquestsBell.shake()
            
        }
    }
    
    @objc func segmentValueChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
            
        case 0:
            onlyUserGroup = false
            
        case 1 :
            onlyUserGroup = true
            
        default:
            return
        }
        tableView.reloadData()
    }
    
    func setUpTableView() {
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: GroupInfo.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        setBuildTeamButton()
        
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    // 查詢團名
    func filtGroupBySearchName(groups: [Group]) -> [Group] {
        
        let fitledGroups = groups.filter {
            $0.routeName.lowercased().prefix(searchText.count) == searchText.lowercased()
            
        }
        
        return fitledGroups
    }

}
// MARK: - SearchBar Delegate -

extension GroupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.alpha = 0
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0.03 * Double(indexPath.row),
            animations: {
                cell.alpha = 1
            })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
        
        let cell: GroupInfo = tableView.dequeueCell(for: indexPath)
        
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

extension GroupViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
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

