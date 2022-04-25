//
//  ChatRoomViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth


class ChatRoomViewController: BaseViewController {
    
    
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
    var groupInfo: Group?
    
    var cache = [String: UserInfo]()
    
    private var userStatus: GroupStatus = .notInGroup
    
    private var headerView: RequestTableViewCell?
    
    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @objc func didTapButton () {
        
        switch userStatus {
            
        case .ishost:
            
            headerView?.isEditting.toggle()
            
            if headerView?.isEditting == true {
                
                headerView?.gButton.setTitle("完成編輯", for: .normal)
                
            } else {
                
                headerView?.gButton.setTitle("編輯資訊", for: .normal)
                
                if let group = headerView?.groupInfo {
                    
                    editGroupInfo(groupInfo: group)
                }
            }
        case .notInGroup:
            
            sendJoinRequest()
            
            headerView?.gButton.setTitle("已送出申請", for: .normal)
            
            headerView?.gButton.isEnabled = false
            
            
        case .isInGroup:
            
            leaveGroup()
        }
        
        
    }
    
    func editGroupInfo(groupInfo: Group) {
        
        GroupManager.shared.updateTeam(group: groupInfo, completion: { result in
            
            switch result {
                
            case .success:
                
                showAlertAction(title: "編輯成功")
                
            case .failure(let error):
                
                print("edit group failure: \(error)")
            }
        })
    }
    
    func sendJoinRequest() {
        
        guard let groupInfo = groupInfo else { return }
        
        let joinRequest = Request( groupId: groupInfo.groupId,
                                  groupName: groupInfo.groupName,
                                  hostId: groupInfo.hostId,
                                  requestId: userInfo.uid,
                                  createdTime: Timestamp())
        
        GroupManager.shared.sendRequest(request: joinRequest) { result in
            
            switch result {
                
            case .success:
                
                showAlertAction(title: "已送出申請")
                
            case .failure(let error):
                
                print("send request failure: \(error)")
            }
        }
    }
    
    func leaveGroup() {
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let leaveAction = UIAlertAction(title: "退出", style: .destructive) { _ in
            
            guard let groupInfo = self.groupInfo else { return }
            
            GroupManager.shared.leaveGroup(groupId: groupInfo.groupId) { result in
                
                switch result {
                    
                case .success:
                    
                    print("User leave group Successfully")
                    
                    self.navigationController?.popViewController(animated: true)
                    
                case .failure(let error):
                    
                    print("leave group failure: \(error)")
                }
            }
        }

        showAlertAction(title: "確認退出", message: nil, actions: [cancelAction, leaveAction])
    }
    
    
}



extension ChatRoomViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        
        let headerView : RequestTableViewCell = .loadFromNib()
        
        self.headerView = headerView
        
        headerView.gButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
    }
    
}
