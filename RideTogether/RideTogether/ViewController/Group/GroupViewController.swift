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

class GroupViewController: BaseViewController, UISearchBarDelegate {

    // MARK: Class Properties
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
    private var inActivityGroup = [Group]()
    
    private var historyGroup = [Group]()
    
    private var myGroups = [Group]()
    
    private var groupHeaderCell: GroupHeaderCell?
    
    private var searchGroups = [Group]()
    
    private var onlyUserGroup = true
    
    private var isSearching = false
    
    private var groupInfo: GroupInfo?
    
    private let header = MJRefreshNormalHeader()
    
    private lazy var cache = [String: UserInfo]() {
        
        didSet {
            tableView.reloadData()
        }
    }
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setBuildTeamButton()
        
        fetchGroupData()
        
        setUpHeaderView()
        
        setUpTableView()
        
    
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
                presentVc.detents = [.medium(),.large()]
            self.navigationController?.present(navBar, animated: true, completion: .none)
        }
        }
    }
    // MARK: 確定時間有沒有過期
    
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
        expiredGroup.sort { $0.date.seconds < $1.date.seconds }
        
        unexpiredGroup.sort { $0.date.seconds < $1.date.seconds }
        
        myGroups =  unexpiredGroup + expiredGroup
    }
    
    // MARK: 抓資料
    
    var filteredGroups = [Group]()
    
    func fetchGroupData() {
        
        GroupManager.shared.fetchGroups { [self] result in
            
            switch result {
                
            case .success(let groups):
                
                filteredGroups = groups
                
//                inActivityGroup = groups
                
//                var filteredGroups = [Group]()
                
//                for group in groups where self.userInfo.blockList?.contains(group.hostId) == false {
//
//                    filteredGroups.append(group)
//                }
                
                self.myGroups = filteredGroups.filter {
                    $0.userIds.contains(self.userInfo.uid)
                }
                
                self.inActivityGroup = filteredGroups.filter { $0.isExpired == false }
                
                self.rearrangeMyGroup(groups: self.myGroups)
                
//                filteredGroups.forEach { group in
//
//                    guard self.cache[group.hostId] != nil else {
//
//                        self.fetchUserData(uid: group.hostId)
//
//                        return
//                    }
//                }
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
    }
    
    
    // MARK: header
    func setUpHeaderView() {
        
        let headerView: GroupHeaderCell = .loadFromNib()
        
        self.groupHeaderCell = headerView
        
        headerView.searchBar.delegate = self
        
        view.addSubview(headerView)
        
//        headerView.groupSearchBar.searchTextField.text = searchText
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            headerView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
//        headerView.requestListButton.addTarget(self, action: #selector(checkRequestList), for: .touchUpInside)
        
          headerView.segment.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
        
//        headerView.groupSearchBar.searchTextField.text = searchText
        
        
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
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    
}

// MARK: - TableView Data Source -

extension GroupViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        filteredGroups.count
        
//        if isSearching {
//
//            return searchGroups.count
//
//        } else {
            
//            if onlyUserGroup {
//
//                return myGroups.count
//
//            } else {
//
//                return inActivityGroup.count
//            }
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: GroupInfo = tableView.dequeueCell(for: indexPath)
        
       
        var group = Group()
        group = filteredGroups[indexPath.row]
        cell.setUpCell(group: group, hostname: cache[group.hostId]?.userName ?? "使用者")
//        if isSearching {
//
//            group = searchGroups[indexPath.row]
//
//        } else {
            
//            if onlyUserGroup {
                
//                group = myGroups[indexPath.row]
                
//            } else {
                
//                group = inActivityGroup[indexPath.row]
//            }
//        }
        
//        cell.setUpCell(group: group, hostname: cache[group.hostId]?.userName ?? "使用者")
        
        return cell
    }
    
    
}
