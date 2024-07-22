//
//  GroupDetailViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import Lottie
import UIKit

protocol ReloadGroupDetail: AnyObject {
    func reloadDetail()
}

class GroupDetailViewController: BaseViewController {
    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    var groupInfo: Group?

    var cache = [String: UserInfo]()

    private var userStatus: GroupStatus = .notInGroup

    private var headerView: RequestTableViewCell?

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }

    private lazy var leaveLottieView: LottieAnimationView = {
        let view = LottieAnimationView(name: "leave")
        view.loopMode = .loop
        view.frame = CGRect(x: UIScreen.width / 2 - 200, y: UIScreen.height / 2 - 200, width: 400, height: 400)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        checkUserStatus()

        headerView?.backgroundColor = .clear

//        setUpChatTextView()

        setUpTableView()

//        tableView.registerCellWithNib(identifier: GroupChatCell.identifier, bundle: nil)

//        addMessageListener()

        setNavigationBar()

//        setUpStatusBarView()

        fetchMemberDate()

//        configureDataSource()
    }

    func checkUserStatus() {
        guard let groupInfo else {
            return
        }

        let isInGroup = groupInfo.userIds.contains(userInfo.uid)

        if groupInfo.hostId == userInfo.uid {
            userStatus = .ishost

        } else {
            userStatus = isInGroup ? .isInGroup : .notInGroup

//            chatTextView.isHidden = isInGroup ? false : true

            self.navigationItem.rightBarButtonItem?.isEnabled = isInGroup ? true : false
        }
    }

    func fetchMemberDate() {
        groupInfo?.userIds.forEach { fetchUserData(uid: $0) }
    }

    func fetchUserData(uid: String) {
        UserManager.shared.fetchUserInfo(uid: uid, completion: { result in

            switch result {
            case let .success(user):

                self.cache[user.uid] = user

            case let .failure(error):

                print("fetchData.failure: \(error)")
            }
        })
    }

    var delegate1: Reload?

    @objc
    func didTapButton() {
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

                let sheet = UIAlertController(title: "編輯成功", message: NSLocalizedString("", comment: "no comment"), preferredStyle: .alert)

                let successOption = UIAlertAction(title: "完成", style: .cancel) { _ in

                    self.dismiss(animated: true, completion: nil)
                }

                sheet.addAction(successOption)
                present(sheet, animated: true, completion: nil)

            case let .failure(error):

                print("edit group failure: \(error)")
            }

        })
    }

    func sendJoinRequest() {
        guard let groupInfo else {
            return
        }

        let joinRequest = Request(groupId: groupInfo.groupId, groupName: groupInfo.groupName, hostId: groupInfo.hostId, requestId: userInfo.uid, createdTime: Timestamp())

        GroupManager.shared.sendRequest(request: joinRequest) { result in

            switch result {
            case .success:

                showAlert(provider: .init(title: "已送出申請", message: "", preferredStyle: .alert, actions: [.init(title: "確認", style: .default)]))

            case let .failure(error):

                print("send request failure: \(error)")
            }
        }
    }

    func leaveGroup() {
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)

        let leaveAction = UIAlertAction(title: "退出", style: .destructive) { _ in

            guard let groupInfo = self.groupInfo else {
                return
            }

            GroupManager.shared.leaveGroup(groupId: groupInfo.groupId) { result in

                switch result {
                case .success:

                    print("User leave group Successfully")

                    self.navigationController?.popViewController(animated: true)

                case let .failure(error):

                    print("leave group failure: \(error)")
                }
            }
            self.leaveLottieView.play()
        }

        showAlert(provider: .init(title: "確認退出", message: "", preferredStyle: .alert, actions: [cancelAction, leaveAction]))
    }

    func setNavigationBar() {
        setNavigationBar(title: "\(groupInfo?.groupName ?? "揪團隊伍")")

        let rightButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        let infoImage = UIImage(systemName: "info")

        rightButton.setImage(infoImage, for: .normal)

        rightButton.addTarget(self, action: #selector(showMembers), for: .touchUpInside)

        self.navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }

    @objc
    func showMembers() {
        if let teammateVC = self.storyboard?.instantiateViewController(
            withIdentifier: "GroupMemberViewController"
        ) as? GroupMemberViewController {
            teammateVC.groupInfo = groupInfo

            teammateVC.cache = cache

            navigationController?.pushViewController(teammateVC, animated: true)
        }
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

extension GroupDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView: RequestTableViewCell = .loadFromNib()

        self.headerView = headerView

        headerView.gButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        if let groupInfo,

           let userInfo = cache[groupInfo.hostId] {
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
