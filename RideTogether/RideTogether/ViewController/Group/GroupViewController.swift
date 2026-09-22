//
//  GroupViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//
//  This used to call UserManager.shared directly (inconsistent with the
//  already-injected groupManager), and had two separate block-list
//  filtering bugs plus a force-unwrap crash risk — all fixed while
//  extracting this logic into GroupViewModel. See that file's header
//  comment for the full rationale. This ViewController now only builds
//  the table/header views, reacts to user actions, and reads
//  viewModel.currentGroups() / viewModel.requests for its data sources.

import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseCrashlytics
import FirebaseFirestore
import MASegmentedControl
import MJRefresh
import UIKit

class GroupViewController: BaseViewController, Reload, UISheetPresentationControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Outlets

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

    var table: UITableView?
    var CreateGroupVC = CreateGroupViewController()

    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with fakes for every dependency.
    var viewModel = GroupViewModel()

    private let header = MJRefreshNormalHeader()
    private var groupHeaderCell: GroupHeaderCell?

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onGroupsUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onRequestsUpdated = { [weak self] in
            self?.checkRequestsNum()
            self?.tabBarController?.tabBar.items?[2].badgeValue = "\(self?.viewModel.requests.count ?? 0)"
            self?.tabBarController?.tabBar.items?[2].badgeColor = .red
        }

        viewModel.fetchGroupData()
        setUpHeaderView()
        viewModel.addRequestListener()
        setUpTableView()
        setUpGradientBackground()

        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))
        tableView.mj_header = header
        table?.delegate = self
        CreateGroupVC.delegate = self

        tapAndDismiss()
        checkRequestsNum()
    }

    // MARK: - Reload Protocol

    func reload() {
        viewModel.fetchGroupData()
    }
}

// MARK: - UI Setup

extension GroupViewController {
    func setUpTableView() {
        tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.registerCellWithNib(identifier: GroupInfo.identifier, bundle: nil)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        setBuildTeamButton()

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func setUpHeaderView() {
        let headerView: GroupHeaderCell = .loadFromNib()
        groupHeaderCell = headerView
        headerView.searchBar.delegate = self
        headerView.searchBar.searchTextField.text = viewModel.searchText
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
        ])

        headerView.resquestsBell.addTarget(self, action: #selector(checkRequestList), for: .touchUpInside)
        headerView.segment.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    func setBuildTeamButton() {
        let button = CreatGroupButton()
        button.addTarget(self, action: #selector(creatGroup), for: .touchUpInside)
        view.addSubview(button)
    }

    func checkRequestsNum() {
        guard let groupHeaderCell = groupHeaderCell, viewModel.requests.count > 0 else { return }
        groupHeaderCell.resquestsBell.shake()
    }
}

// MARK: - Actions

extension GroupViewController {
    @objc func creatGroup() {
        let rootVC = CreateGroupViewController()
        let navBar = UINavigationController(rootViewController: rootVC)
        if #available(iOS 15.0, *), let sheet = navBar.sheetPresentationController {
            sheet.detents = [.large(), .medium()]
            rootVC.delegate = self
            navigationController?.present(navBar, animated: true)
        } else {
            LKProgressHUD.showFailure(text: "無法創建活動")
        }
    }

    @objc func checkRequestList(_ sender: UIButton) {
        guard viewModel.requests.count > 0 else { return }

        let vc = JoinViewController(requests: viewModel.requests)

        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func headerRefresh() {
        viewModel.fetchGroupData()
        tableView.mj_header?.endRefreshing()
    }

    @objc func segmentValueChanged(_ sender: UISegmentedControl) {
        viewModel.onlyUserGroup = sender.selectedSegmentIndex == 1
        tableView.reloadData()
    }

    func tapAndDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyBoard))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyBoard() {
        groupHeaderCell?.searchBar.resignFirstResponder()
    }
}

// MARK: - TableView Delegate

extension GroupViewController: UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.03 * Double(indexPath.row)) {
            cell.alpha = 1
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        200
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let groups = viewModel.currentGroups()
        let group = groups[indexPath.row]

        let vc = ChatRoomViewController(groupInfo: group, cache: viewModel.hostCache)

        self.navigationController?.pushViewController(vc, animated: false)
    }
}

// MARK: - TableView DataSource

extension GroupViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.currentGroups().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: GroupInfo = tableView.dequeueCell(for: indexPath)
        let group = viewModel.currentGroups()[indexPath.row]
        cell.setUpCell(group: group, hostname: viewModel.hostCache[group.hostId]?.userName ?? "使用者")
        return cell
    }
}

// MARK: - SearchBar Delegate

extension GroupViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        viewModel.updateSearch(text: searchText)
        tableView.reloadData()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.endSearch()
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

