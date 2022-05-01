//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import UIKit
import MJRefresh
import SwiftUI
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore
import Lottie


class RouteViewController: BaseViewController {
    
    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var dataBase = Firestore.firestore()
    
    private let routeCollection = Collection.routes.rawValue
    
    var indexOfRoute:Int = 0
    
    var routes = [Route]()
    
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    func backButton() {
        let button = PreviousPageButton(frame: CGRect(x: 30, y: 50, width: 40, height: 40))
        view.addSubview(button)
    }
    
    
    func setUpTableView() {
        
        setNavigationBar(title: "Routes")
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: RoutesTableViewCell.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    func fetchRecords() {
        
        MapsManager.shared.fetchRoutes { [weak self] result in
            switch result {
            case .success(let route):
                self?.routes = route
                self?.tableView.reloadData()
            case .failure(let error): print ("fetchData Failure: \(error)")
            }
        }
    }
    
    @objc func headerRefresh() {
        
        //        fetchRecords()
        
        tableView.reloadData()
        
        self.tableView.mj_header?.endRefreshing()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        
        //        fetchRecords()
        
        tableView.mj_header = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        tabBarController?.tabBar.isHidden = false
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        waitlottie.isHidden = true
    }
    
    private lazy var waitlottie : AnimationView = {
        let view = AnimationView(name: "waiting-pigeon")
        view.loopMode = .loop
        view.frame = CGRect(x: UIScreen.width / 8 , y: UIScreen.height / 6  , width: 300 , height: 300)
        view.cornerRadius = 20
        view.contentMode = .scaleToFill
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
}

extension RouteViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        waitlottie.isHidden = false
        
        waitlottie.play()
        
        
        
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "RouteRideViewController") as? RouteRideViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.routes = routes[indexPath.row]
        }
     
    }
    
}

extension RouteViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(model: self.routes[indexPath.row])
        
        return cell
    }
    
}
