//
//  JoinViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/22.
//

import UIKit

class JoinViewController: BaseViewController {
    
    // MARK: - DataSource & DataSourceSnapshot typelias -
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Request>
    
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Request>
    
    // MARK: - Class Properties -
    
    enum Section {
        case section
    }
    
    private var dataSource: DataSource!
    
    lazy var requests = [Request]() {
        
        didSet {
            
            requests.forEach { request in
                
                fetchUserData(uid: request.requestId)
            }
        }
    }
    
    private lazy var cache = [String: UserInfo]()
    
    func fetchUserData(uid: String) {
        
        let group = DispatchGroup()
        
        group.enter()
                
        UserManager.shared.fetchUserInfo(uid: uid, completion: { result in
            
            switch result {
                
            case .success(let user):
                
                self.cache[user.uid] = user
                
                group.leave()
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        })
        
        group.notify(queue: DispatchQueue.main) {
            
            self.tableView.reloadData()
        }
        
    }
    
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    


}
