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

class SaveMapsViewController: BaseViewController {

    var userId: String { UserManager.shared.userInfo.uid }
    
    var records = [Record]()
    
    
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUptableView()
        
        fetchRecords()
        
        tableView.mj_header? = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))
        
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
        
        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))
        
        setNavigationBar(title: "SaveMaps")
        
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
    
    

}

extension SaveMapsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alert = UIAlertController(title: "Choose", message: nil, preferredStyle: .alert)
        
        let detailOption = UIAlertAction(title: "Show Detail", style: .default) { [self] _ in
            
            if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "FollowJourneyViewController") as? FollowJourneyViewController {
                navigationController?.pushViewController(journeyViewController, animated: true)
                journeyViewController.record = records[indexPath.row]}
            
        }
        let removeOption = UIAlertAction(title: "Delete it", style: .destructive) {
            [self] _ in
            
            MapsManager.shared.deleteDbRecords(recordId: records[indexPath.row].recordId) { result in
                
                switch result {
                    
                case .success(_):
                    
                    self.records.remove(at: indexPath.row)
                    
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                    
                case .failure(let error):
                    
                    print ("delete error: \(error)")
                }
            }
            
        }
        
        let cancelOption = UIAlertAction(title: "cancel", style: .cancel){ _ in }
        
        alert.addAction(detailOption)
        alert.addAction(removeOption)
        alert.addAction(cancelOption)
        
        present(alert, animated: true, completion: nil)
        
        
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
