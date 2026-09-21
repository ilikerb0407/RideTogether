//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import Lottie
import QuartzCore
import UIKit

class HomeViewController: BaseViewController, Reload {
    func reload() {}

    var trackVC = TracksViewController()

    private var headerView: HomeHeader?

    private var userInfo: UserInfo { UserManager.shared.userInfo }

    var routes = [RouteModel]() {
        didSet {
            manageRouteData()
        }
    }

    var userOne = [RouteModel]()

    var recommendOne = [RouteModel]()

    var riverOne = [RouteModel]()

    var mountainOne = [RouteModel]()

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

        setUpGradientBackground()

        setUpTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchTrailData()
    }

    // Was `@IBOutlet var gView: UIView! { didSet { ... } }` — the storyboard
    // provided an empty background view whose only job is a gradient
    // fill, built in code here instead. Layout matches Home.storyboard's
    // scene exactly: top pinned to the root view (bleeds behind the nav
    // bar), leading/trailing/bottom pinned to the safe area.
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

    func setUpTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)

        tableView.registerCellWithNib(identifier: RouteTypes.identifier, bundle: nil)

        view.stickSubView(tableView)

        tableView.backgroundColor = .clear

        tableView.separatorStyle = .none
    }

    @objc func updateUserInfo(notification _: Notification) {
        guard let headerView = headerView else { return }

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
        MapsManager.shared.fetchRoutes { result in

            switch result {
            case let .success(routes):

                var filterroutes = [RouteModel]()

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
        let headerView: HomeHeader = .loadFromNib()

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
        var sender = [RouteModel]()

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
        performSegue(withIdentifier: SegueIdentifier.route.rawValue, sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.route.rawValue {
            if let routeListVC = segue.destination as? RouteViewController {
                if let routes = sender as? [RouteModel] {
                    routeListVC.routes = routes
                }
            }
        }
    }
}

// MARK: - TableView Data Source -

extension HomeViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        RouteCategory.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RouteTypes = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(
            routetitle: RouteCategory.allCases[indexPath.row].rawValue,
            routephoto: RouteCategory.allCases[indexPath.row].image ?? UIImage(named: "routesphoto")!
        )

        return cell
    }
}
