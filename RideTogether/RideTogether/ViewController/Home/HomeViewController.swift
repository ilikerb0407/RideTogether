//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import UIKit
import Lottie

class HomeViewController: BaseViewController {
    
    
    private var headerView: HomeHeader?
    
    var routes = [Route]() {
        didSet {
            manageRouteData()
        }
    }
    
    var recommendOne = [Route]()
    
    var riverOne = [Route]()
    
    var mountainOne = [Route]()
    
    private var tableView: UITableView! {
        
        didSet {
            
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

//        private lazy var bikelottie : AnimationView = {
//            let view = AnimationView(name: "bike-city-rider")
//            view.loopMode = .loop
//            view.frame = CGRect(x: UIScreen.width / 8 , y: 50 , width: 200 , height: 180)
//            view.cornerRadius = 20
//            view.contentMode = .scaleToFill
//            view.play()
//            self.view.addSubview(view)
//            return view
//        }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserInfo),
            name: NSNotification.userInfoDidChanged,
            object: nil
        )
        
        
        setUpTableView()
        
        fetchTrailData()
        
        
        
        
//        bikelottie.play()
        
    }
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .U1],
                locations: [0.0, 2.0], direction: .leftSkewed)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
//        bikelottie.play()
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
        
        for route in routes {
            
            switch route.routeTypes {
            case 0 :
                recommendOne.append(route)
            case 1 :
                riverOne.append(route)
            case 2 :
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
        400
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var sender = [Route]()
        
        switch indexPath.row {
        case 0 :
            sender = recommendOne
        case 1 :
            sender = riverOne
        case 2 :
            sender = mountainOne
        default:
            return
        }
        performSegue(withIdentifier: SegueIdentifier.route.rawValue, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.route.rawValue {
            if let routeListVC = segue.destination as? RouteViewController{
                
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
