//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import QuartzCore
import UIKit

internal class HomeViewController: BaseViewController {

    // MARK: - Properties
    
    private let viewModel: HomeViewModel
    private var trackVC = TracksViewController()
    private var headerView: HomeHeaderTableViewCell?
    
    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }
    
    // MARK: - Initialization
    
    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = HomeViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewModel()
        setupNotifications()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchTrailData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserInfo),
            name: NSNotification.userInfoDidChanged,
            object: nil
        )
    }
    
    private func setUpTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.registerCellWithNib(identifier: RouteTypesTableViewCell.identifier, bundle: nil)
        view.stickSubView(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
    }
    
    // MARK: - Actions
    
    @objc func updateUserInfo(notification _: Notification) {
        guard let headerView else { return }
        headerView.updateUserInfo(user: UserManager.shared.userInfo)
    }
    
    private func push(sender: Any?) {
        if let routeViewController = storyboard?.instantiateViewController(withIdentifier: "RouteViewController") as? RouteViewController {
            if let routes = sender as? [Route] {
                routeViewController.viewModel.setRoutes(routes)
            }
            navigationController?.pushViewController(routeViewController, animated: true)
        }
    }
}

// MARK: - HomeViewModelDelegate

extension HomeViewController: HomeViewModelDelegate {
    func didUpdateRoutes() {
        tableView.reloadData()
    }
    
    func didUpdateUserInfo() {
        guard let headerView else { return }
        headerView.updateUserInfo(user: UserManager.shared.userInfo)
    }
    
    func didFailWithError(_ error: Error) {
        print("fetchData.failure: \(error)")
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView: HomeHeaderTableViewCell = .loadFromNib()
        self.headerView = headerView
        headerView.updateUserInfo(user: UserManager.shared.userInfo)
        return self.headerView
    }
    
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        270
    }
    
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let routes = viewModel.getRoutesForType(indexPath.row)
        push(sender: routes)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        RoutesType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RouteTypesTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(
            routetitle: RoutesType.allCases[indexPath.row].title,
            routephoto: RoutesType.allCases[indexPath.row].image ?? UIImage(named: "routesPhoto")!
        )
        
        return cell
    }
}
