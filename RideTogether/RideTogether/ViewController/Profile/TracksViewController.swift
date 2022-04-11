//
//  TracksViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import UIKit
import MJRefresh

class TracksViewController: BaseViewController {

    
    var records = [Record]()
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    func setUpTableView() {
        
        setNavigationBar(title: "TrackTableView")
        
        tableView = UITableView(frame: .zero, style: .plain)
        
        tableView.registerCellWithNib(identifier: TrackTableViewCell.identifier, bundle: nil)
        
        view.stickSubView(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
    }
    
    func fetchRecords() {
        RecordManager.shared.fetchRecords { [weak self] result in
            switch result {
            case .success(let records):
                self?.records = records
                self?.tableView.reloadData()
            case .failure(let error):
                print ("fetchData Failure: \(error)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        
        fetchRecords()
        
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    
}


extension TracksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
}

extension TracksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TrackTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(model: self.records[indexPath.row])
        
        return cell
    }
}
