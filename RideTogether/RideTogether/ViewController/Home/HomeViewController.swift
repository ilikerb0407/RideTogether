//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import UIKit
import Lottie

class HomeViewController: BaseViewController {

    
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
    
  
        
        private lazy var bikelottie : AnimationView = {
            let view = AnimationView(name: "bike-city-rider")
            view.loopMode = .loop
            view.frame = CGRect(x: UIScreen.width / 8 , y: 50 , width: 200 , height: 180)
            view.cornerRadius = 20
            view.contentMode = .scaleToFill
            view.play()
            self.view.addSubview(view)
            return view
        }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .B4
        
        navigationController?.isNavigationBarHidden = true
        
        setUpTableView()
        
        fetchTrailData()
        
        manageRouteData()
        
        bikelottie.play()
        


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setUpTableView()
        
        bikelottie.play()
    }
    
    func setUpTableView() {
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: RouteTypes.identifier, bundle: nil)
        
//        view.stickSubView(tableView)
        view.addSubview(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
        tableView.isScrollEnabled = false
        
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: bikelottie.bottomAnchor, constant: 10),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
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
