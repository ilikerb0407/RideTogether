//
//  JoinViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/22.
//

import UIKit

class JoinViewController: BaseViewController {
    
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }
    
    
    
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
    
    private var tableView: UITableView!
    
    private lazy var dimmingView = UIView()
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpDimmingView()
        
        setUpTableView()
        
        setUpDismissButton()
        
        configureDataSource()
        
        configureSnapshot()
        
        
    }
    
    // MARK: - Methods -
    
    func addRequestListener() {
        
        GroupManager.shared.addRequestListener { result in
            
            switch result {
                
            case .success(let requests):
                
                self.requests = requests
                
                self.configureSnapshot()
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
    }
    
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
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func acceptRequest(_ sender: UIButton) {
        
        GroupManager.shared.addUserToGroup(
            groupId: requests[sender.tag].groupId,
            userId: requests[sender.tag].requestId
        ) { result in
            
            switch result {
                
            case .success:
                
                print("add user to group succesfully")
                
            case .failure(let error):
                
                print("add user to group failure: \(error)")
            }
        }
        
        GroupManager.shared.removeRequest(
            groupId: requests[sender.tag].groupId,
            userId: requests[sender.tag].requestId
        ) { result in
            switch result {
                
            case .success:
                
                print("accept succesfully")
                
                self.requests.remove(at: sender.tag)
                
                self.configureSnapshot()
                
            case .failure(let error):
                
                print("accept failure: \(error)")
                
            }
        }
    }
    
    @objc func rejectRequest(_ sender: UIButton) {
        
        GroupManager.shared.removeRequest(
            groupId: requests[sender.tag].groupId,
            userId: requests[sender.tag].requestId
        ) { result in
            
            switch result {
                
            case .success:
                
                print("reject succesfully")
                
                self.requests.remove(at: sender.tag)
                
                self.configureSnapshot()
                
            case .failure(let error):
                
                print("reject failure: \(error)")
            }
        }
    }
    
    // MARK: - UI Settings -
    
    func setUpTableView() {
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: Member.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setUpDismissButton() {
        
        let button = DismissButton(frame: CGRect(x: UIScreen.width - 50, y: 30, width: 30, height: 30))
        
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    func setUpDimmingView() {
        
        view.stickSubView(dimmingView)
        
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        
        dimmingView.addGestureRecognizer(recognizer)
    }
    
}

extension JoinViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        300
    }
}

// MARK: - Diffable Data Source -

extension JoinViewController {
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { ( tableView, indexPath, model) -> UITableViewCell? in
            
            let cell: Member = tableView.dequeueCell(for: indexPath)
            
            if let user = self.cache[self.requests[indexPath.row].requestId] {
                
                cell.setUpCell(model: model, userInfo: user)
            }
            
            cell.acceptButton.addTarget(self, action: #selector(self.acceptRequest), for: .touchUpInside)
            
            cell.acceptButton.tag = indexPath.row
            
            cell.rejectButton.addTarget(self, action: #selector(self.rejectRequest), for: .touchUpInside)
            
            cell.rejectButton.tag = indexPath.row
            
            return cell
        }
    }
    
    func configureSnapshot() {
        
        var snapshot = DataSourceSnapshot()
        
        snapshot.appendSections([.section])
        
        snapshot.appendItems(requests, toSection: .section)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
