//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import QuartzCore
import UIKit

class HomeViewController: BaseViewController {
    func reloadDetail() { }

    var trackVC = TracksViewController()

    private var headerView: HomeHeaderTableViewCell?

    private var userInfo: UserInfo { UserManager.shared.userInfo }

    var routes = [Route]() {
        didSet {
            manageRouteData()
        }
    }

    var userOne = [Route]()

    var recommendOne = [Route]()

    var riverOne = [Route]()

    var mountainOne = [Route]()

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserInfo),
            name: NSNotification.userInfoDidChanged,
            object: nil
        )

        setUpTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchTrailData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    func setUpTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)

        tableView.registerCellWithNib(identifier: RouteTypesTableViewCell.identifier, bundle: nil)

        view.stickSubView(tableView)

        tableView.backgroundColor = .clear

        tableView.separatorStyle = .none
    }

    @objc
    func updateUserInfo(notification _: Notification) {
        guard let headerView else {
            return
        }

        headerView.updateUserInfo(user: UserManager.shared.userInfo)
    }

    func manageRouteData() {
        userOne = []

        recommendOne = []

        riverOne = []

        mountainOne = []

        for route in routes {
            switch route.routeTypes {
            case 0:
                userOne.append(route)
            case 1:
                recommendOne.append(route)
            case 2:
                riverOne.append(route)
            case 3:
                mountainOne.append(route)
            default:
                return
            }
        }
    }

    func fetchTrailData() {
        //////Test
        MapsManager.shared.fetchRoutes { result in
            ////
            switch result {
            case let .success(routes):

                var filterroutes = [Route]()

                for maps in routes where self.userInfo.blockList?.contains(maps.uid ?? "") == false {
                    filterroutes.append(maps)
                }
                self.routes = filterroutes

                self.tableView.reloadData()

            case let .failure(error):

                print("fetchData.failure: \(error)")
            }
        }
    }
}

// MARK: - TableView Delegate -

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
        var sender = [Route]()

        switch indexPath.row {
        case 0:
            sender = userOne
        case 1:
            sender = recommendOne
        case 2:
            sender = riverOne
        case 3:
            sender = mountainOne
        default:
            return
        }
        push(sender: sender)
    }

    func push(sender: Any?) {
        if let routeViewController = storyboard?.instantiateViewController(withIdentifier: "RouteViewController") as? RouteViewController {
            if let routes = sender as? [Route] {
                routeViewController.routes = routes
            }
            navigationController?.pushViewController(routeViewController, animated: true)
        }
    }
}

// MARK: - TableView Data Source -

extension HomeViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        RoutesType.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RouteTypesTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(
            routetitle: RoutesTypeTest.allCases[indexPath.row].title,
            routephoto: RoutesTypeTest.allCases[indexPath.row].image ?? UIImage(named: "routesPhoto")!
        )

        return cell
    }
}
