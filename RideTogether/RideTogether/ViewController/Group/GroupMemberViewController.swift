//
//  GroupMemberViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/2.
//

import UIKit

class GroupMemberViewController: BaseViewController {
    var cache: [String: UserInfo]?
    
    init(cache: [String : UserInfo]? = nil, groupInfo: Group? = nil) {
        self.cache = cache
        self.groupInfo = groupInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    var groupInfo: Group?

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self

            tableView.dataSource = self
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
            gView.topAnchor.constraint(equalTo: view.topAnchor),
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView()

        tableView.backgroundColor = .clear

        tableView.registerCellWithNib(identifier: Member.identifier, bundle: nil)

        view.stickSubView(tableView)

        setNavigationBar(title: "\(groupInfo?.groupName ?? "揪團") - 成員")
        
        setUpGradientBackground()
    }
}

// MARK: - TableView Delegate & Data Source -

extension GroupMemberViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let num = groupInfo?.userIds.count else { fatalError() }

        return num
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: Member = tableView.dequeueCell(for: indexPath)

        if let group = groupInfo,

           let userInfo = cache?[group.userIds[indexPath.row]]
        {
            cell.setUpCell(group: group, userInfo: userInfo)

            cell.rejectButton.addTarget(self, action: #selector(blockUser), for: .touchUpInside)

            cell.rejectButton.tag = indexPath.row
        }

        return cell
    }

    @objc func blockUser(_ sender: UIButton) {
        if let blockUserId = groupInfo?.userIds[sender.tag] {
            showBlockAlertAction(uid: blockUserId)
        }
    }
}
