//
//  HomeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/14.
//

import UIKit

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .B4
        
        setUpTableView()
        
        fetchTrailData()
        
    }
    
    
    func setUpTableView() {
        
        tableView = UITableView(frame: .zero, style: .grouped)
        
        tableView.registerCellWithNib(identifier: RouteTypes.identifier, bundle: nil)
        
        view.stickSubView(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
    }
    
    func manageRouteData(){
        
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
        
        
    }
    
}

// MARK: - TableView Delegate -

extension HomeViewController: UITableViewDelegate {
    
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
        performSegue(withIdentifier: SegueIdentifier.routeList.rawValue, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.routeList.rawValue {
            if let routeListVC = segue.destination as? RouteViewController{
                
                if let routes = sender as? [Route] {
                    
                    routeListVC.route = routes
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
            routephoto: RoutesType.allCases[indexPath.row].image ?? UIImage(named: "IMG_3635")!)
        
        if indexPath.row % 2 == 1 {
            cell.routeTitle.textColor = .black
        }
        
        return cell
    }
}
