//
//  GroupMemberViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/2.
//

import UIKit

class GroupMemberViewController: BaseViewController {
    
    var cache: [String: UserInfo]?
    
    var groupInfo: Group?
    
    private var tableView: UITableView! {
        
        didSet {
            
            tableView.delegate = self
            
            tableView.dataSource = self
        }
    }
    
    @IBOutlet weak var gView: UIView! {
        didSet{
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView()
        
        tableView.backgroundColor = .clear
        
        tableView.registerCellWithNib(identifier: Member.identifier, bundle: nil)
        
        view.stickSubView(tableView)
        
        setNavigationBar(title: "\(groupInfo?.groupName ?? "揪團") - 成員")

    }
    

}

// MARK: - TableView Delegate & Data Source -

extension GroupMemberViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let num =  groupInfo?.userIds.count else { fatalError() }
        
        return num
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: Member = tableView.dequeueCell(for: indexPath)
        
        if let group = groupInfo,
           
           let userInfo = cache?[group.userIds[indexPath.row]] {
            
            cell.setUpCell(group: group, userInfo: userInfo)
            
            cell.rejectButton.addTarget(self, action: #selector(blockUser), for: .touchUpInside)
            
            cell.rejectButton.tag = indexPath.row
            
        }
        
        return cell
    }
    
    @objc func blockUser (_ sender: UIButton) {
        
        if let blockUserId = self.groupInfo?.userIds[sender.tag] {
            
            showBlockAlertAction(uid: blockUserId)
        }
    }
}
