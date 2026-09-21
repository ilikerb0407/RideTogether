//
//  JoinViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/22.
//

import Firebase
import UIKit

class JoinViewController: BaseViewController {

    typealias DataSource = UITableViewDiffableDataSource<Section, Request>

    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Request>

    enum Section {
        case section
    }

    private var dataSource: DataSource!

    // TODO: Combine 的話，改 @Published
    var requests: [Request]? {
        didSet {
            fetchUsersForCurrentRequests()
        }
    }
    
    private var cache: [String: UserInfo]
    
    init(requests: [Request]? = nil, cache: [String: UserInfo] = [:]) {
        self.requests = requests
        self.cache = cache
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        super.init(coder: coder)
    }

    private var tableView: UITableView!

    private lazy var dimmingView = UIView()
    private var requestListenerRegistration: ListenerRegistration?

    deinit {
        requestListenerRegistration?.remove()
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
            gView.topAnchor.constraint(equalTo: view.topAnchor),
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        
        setUpGradientBackground()
        
        configureDataSource()

        fetchUsersForCurrentRequests()
    }
    
    func addRequestListener() {
        requestListenerRegistration = GroupManager.shared.addRequestListener { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(requests):
                
                var uniqueRequests = [Request]()
                var seenRequestIds = Set<String>()

                for req in requests {
                    if !seenRequestIds.contains(req.requestId) {
                        seenRequestIds.insert(req.requestId)
                        uniqueRequests.append(req)
                    }
                }

                self.requests = uniqueRequests
                self.fetchUsersForCurrentRequests()

            case let .failure(error):
                print("fetchData.failure: \(error)")
            }
        }
    }
    
    func fetchUsersForCurrentRequests() {
        guard let requests = requests else { return }
        
        let group = DispatchGroup()
        
        for request in requests {
            let uid = request.requestId

            guard cache[uid] == nil else { continue }
            
            group.enter()
            UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
                defer { group.leave() }
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    self.cache[user.uid] = user
                case .failure(let error):
                    print("fetchUserInfo failure: \(error)")
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            // 當所有 User 資料抓取完成後，更新 UI
            self?.configureSnapshot()
        }
    }

    @objc func handleTap(recognizer _: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @objc func acceptRequest(_ sender: UIButton) {
        guard let requests else { return }
        GroupManager.shared.addUserToGroup(
            groupId: requests[sender.tag].groupId,
            userId: requests[sender.tag].requestId
        ) { result in

            switch result {
            case .success:

                print("add user to group succesfully")

            case let .failure(error):

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

                self.requests?.remove(at: sender.tag)

                self.configureSnapshot()

            case let .failure(error):

                print("accept failure: \(error)")
            }
        }
    }

    @objc func rejectRequest(_ sender: UIButton) {
        guard let requests else { return }
        GroupManager.shared.removeRequest(
            groupId: requests[sender.tag].groupId,
            userId: requests[sender.tag].requestId
        ) { result in

            switch result {
            case .success:

                print("reject succesfully")

                self.requests?.remove(at: sender.tag)

                self.configureSnapshot()

            case let .failure(error):

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
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func setUpDismissButton() {
        let button = DismissButton(frame: CGRect(x: UIScreen.width - 50, y: 30, width: 30, height: 30))

        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        button.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
    }

    func setUpDimmingView() {
        view.stickSubView(dimmingView)

        dimmingView.translatesAutoresizingMaskIntoConstraints = false

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))

        dimmingView.addGestureRecognizer(recognizer)
    }
    
    func fetchSingleUserIfNeeded(uid: String) {
        // 1. 如果快取中已經有了，直接返回
        guard cache[uid] == nil else { return }

        // 2. 抓取單一使用者資料
        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let user):
                // 寫入快取
                self.cache[user.uid] = user

                // 抓到資料後，觸發重新套用 Snapshot (或指定 item reconfigure)，讓表格更新顯示
                DispatchQueue.main.async {
                    self.configureSnapshot()
                }

            case .failure(let error):
                print("fetchSingleUserIfNeeded failure: \(error)")
            }
        }
    }
}

extension JoinViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        300
    }
}

// MARK: - Diffable Data Source -

extension JoinViewController {
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, model -> UITableViewCell? in
            guard let self = self else { return nil }

            let cell: Member = tableView.dequeueCell(for: indexPath)

            // 檢查快取
            if let user = self.cache[model.requestId] {
                cell.setUpCell(model: model, userInfo: user)
            } else {
                // 快取沒有資料時，先顯示基礎 Model（或空的 UI），並觸發非同步抓取
                cell.setUpCell(model: model, userInfo: UserInfo()) // 假設你的 setUpCell 支持帶 nil
                self.fetchSingleUserIfNeeded(uid: model.requestId)
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
        
        guard let requests else { return }
        
        snapshot.appendSections([.section])

        snapshot.appendItems(requests, toSection: .section)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
