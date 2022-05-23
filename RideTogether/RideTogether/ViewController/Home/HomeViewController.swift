//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import UIKit
import Lottie
import QuartzCore

class HomeViewController: BaseViewController, Reload {
    
    func reload() {
        
    }
    
    var trackVC = TracksViewController()
    
    
    private var headerView: HomeHeader?
    
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
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }
    
    func setUpTableView() {
        
        tableView = UITableView(frame: .zero, style: .grouped)
        
        tableView.registerCellWithNib(identifier: RouteTypes.identifier, bundle: nil)
        
        view.stickSubView(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
    }
    
    @objc func updateUserInfo(notification: Notification) {
        
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
                
            case 0 :
                userOne.append(route)
            case 1 :
                recommendOne.append(route)
            case 2 :
                riverOne.append(route)
            case 3 :
                mountainOne.append(route)
            default:
                return
            }
        }
        
    }
    
    func fetchTrailData() {
        
        MapsManager.shared.fetchRoutes { result in
            
            switch result {
                
            case .success(let routes):
                
                self.routes = routes
                
                self.tableView.reloadData()
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
        
    }
    
}

// MARK: - TableView Delegate -

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView: HomeHeader = .loadFromNib()
        
        self.headerView = headerView

        headerView.updateUserInfo(user: UserManager.shared.userInfo)
        
        return self.headerView
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        270
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var sender = [Route]()
        
        switch indexPath.row {
        case 0 :
            sender = userOne
        case 1 :
            sender = recommendOne
        case 2 :
            sender = riverOne
        case 3 :
            sender = mountainOne
        default:
            return
        }
        performSegue(withIdentifier: SegueIdentifier.route.rawValue, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.route.rawValue {
            
            if let routeListVC = segue.destination as? RouteViewController {
                
                if let routes = sender as? [Route] {
                    routeListVC.routes = routes
                }
            }
        }
    }
}

// MARK: - TableView Data Source -

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        RoutesType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: RouteTypes = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(
            routetitle: RoutesType.allCases[indexPath.row].rawValue,
            routephoto: RoutesType.allCases[indexPath.row].image ?? UIImage(named: "routesphoto")!)
    
        return cell
    }
    
}
