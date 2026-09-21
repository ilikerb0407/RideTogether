//
//  ChatRoomViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import Lottie
import UIKit

class ChatRoomViewController: BaseViewController {

    private var userInfo: UserInfo { UserManager.shared.userInfo }

    var groupInfo: Group?

    var cache: [String: UserInfo]?
    
    init(groupInfo: Group? = nil, cache: [String : UserInfo]? = [String: UserInfo]()) {
        self.groupInfo = groupInfo
        self.cache = cache
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    private var userStatus: GroupStatus = .notInGroup

    private var headerView: RequestTableViewCell?

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }
    
    private lazy var gView: UIView = {
        let gradientView = UIView()
        gradientView.applyGradient(
            colors: [.white, .B3],
            locations: [0.0, 1.0], direction: .leftSkewed
        )
        gradientView.alpha = 0.85
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()

    private func setUpGradientBackground() {
        view.insertSubview(gView, at: 0)

        NSLayoutConstraint.activate([
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            gView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -125),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserStatus()
        
        setUpGradientBackground()
        
        headerView?.backgroundColor = .clear
        
        setUpTableView()
        
        setNavigationBar()
        
        fetchMemberDate()
    }

    func checkUserStatus() {
        guard let groupInfo = groupInfo else { return }

        let isInGroup = groupInfo.userIds.contains(userInfo.uid)

        if groupInfo.hostId == userInfo.uid {
            userStatus = .ishost

        } else {
            userStatus = isInGroup ? .isInGroup : .notInGroup

//            chatTextView.isHidden = isInGroup ? false : true

            navigationItem.rightBarButtonItem?.isEnabled = isInGroup ? true : false
        }
    }

    func fetchMemberDate() {
        groupInfo?.userIds.forEach { fetchUserData(uid: $0) }
    }

    func fetchUserData(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid, completion: { result in

            switch result {
            case let .success(user):

                self.cache?[user.uid] = user

            case let .failure(error):

                print("fetchData.failure: \(error)")
            }
        })
    }

    @objc func didTapButton() {
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

            case let .failure(error):

                print("edit group failure: \(error)")
            }
        })
    }
    
    @objc func sendJoinRequest(_ sender: UIButton? = nil) {
        guard let groupInfo = groupInfo else { return }

        // 如果有傳入 sender 就停用按鈕
        sender?.isEnabled = false

        let joinRequest = Request(
            groupId: groupInfo.groupId,
            groupName: groupInfo.groupName,
            hostId: groupInfo.hostId,
            requestId: userInfo.uid,
            createdTime: Timestamp()
        )

        GroupManager.shared.sendRequest(request: joinRequest) { [weak self] result in
            sender?.isEnabled = true

            switch result {
            case .success:
                self?.showAlertAction(title: "已送出申請")
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

                case let .failure(error):

                    print("leave group failure: \(error)")
                }
            }
        }

        showAlertAction(title: "確認退出", message: nil, actions: [cancelAction, leaveAction])
    }

    func setNavigationBar() {
        setNavigationBar(title: "\(groupInfo?.groupName ?? "揪團隊伍")")

        let rightButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        let infoImage = UIImage(systemName: "info")

        rightButton.setImage(infoImage, for: .normal)

        rightButton.addTarget(self, action: #selector(showMembers), for: .touchUpInside)

        navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }

    @objc func showMembers() {
        let teammateVC = GroupMemberViewController()
        
        teammateVC.groupInfo = groupInfo

        teammateVC.cache = cache

        navigationController?.pushViewController(teammateVC, animated: true)
    }

    func setUpTableView() {
        tableView = UITableView()

        view.addSubview(tableView)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none

        tableView.bounces = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension ChatRoomViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView: RequestTableViewCell = .loadFromNib()

        self.headerView = headerView

        headerView.gButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        if let groupInfo = groupInfo,

            let userInfo = cache?[groupInfo.hostId]
        {
            headerView.setUpCell(group: groupInfo, cache: userInfo, userStatus: userStatus)
        }

        return headerView.contentView
    }

    func tableView(_: UITableView, estimatedHeightForHeaderInSection _: Int) -> CGFloat {
        200
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        300
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        300
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        200
    }
}
