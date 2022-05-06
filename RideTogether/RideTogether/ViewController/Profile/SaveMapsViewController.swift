//
//  SaveMapsViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/30.
//

import UIKit
import MJRefresh
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift
import Lottie
import AVFoundation

class SaveMapsViewController: BaseViewController {
    
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    var records = [Record]()
    
    
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    private let header = MJRefreshNormalHeader()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUptableView()
        
        fetchRecords()
        
        tableView.mj_header = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        tabBarController?.tabBar.isHidden = false
        
    }
    
    @objc func headerRefresh() {
        
        fetchRecords()
        
        tableView.reloadData()
        
        self.tableView.mj_header?.endRefreshing()
    }
    
    // fetch uid
    func fetchRecords() {
        
        MapsManager.shared.fetchSavemaps { [weak self] result  in
            switch result {
            case .success(let records):
                self?.records = records
                self?.tableView.reloadData()
            case .failure(let error): print ("fetchData Failure: \(error)")
            }
        }
    }
    
    func setUptableView() {
        
        setNavigationBar(title: "收藏路線")
        
        tableView = UITableView()
        // 借用同一個tableViewcell
        
        tableView.registerCellWithNib(identifier: SaveMaps.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    func deleteMapsFromUser(uid: String, savemaps: String) {
        
        MapsManager.shared.deleteMapFromUser(uid: userId) { result in
            switch result {
            case .success:
                print ("success")
            case .failure(let error):
                print ("\(error)")
            }
        }
    }
    
    

}

extension SaveMapsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
            if editingStyle == .delete {
              
                MapsManager.shared.deleteDbRecords(recordId: records[indexPath.row].recordId) { [self] result in
                    
                    switch result {
                        
                    case .success(_):
                        
                        self.records.remove(at: indexPath.row)
                        
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                        
//                      self.deleteMapsFromUser(uid: userId, savemaps: UserInfo.CodingKeys.saveMaps.rawValue)
                        
                    case .failure(let error):
                        
                        print ("delete error: \(error)")
                    }
                }
            }
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

            if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "FollowJourneyViewController") as? FollowJourneyViewController {
                navigationController?.pushViewController(journeyViewController, animated: true)
                journeyViewController.record = records[indexPath.row]}
            
  
    }
    
    
}

extension SaveMapsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: SaveMaps = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(model: self.records[indexPath.row])
        
        
        return cell
    }
    
    
}
