//
//  TracksViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import UIKit
import MJRefresh
import SwiftUI


//MARK: User Record

class TracksViewController: BaseViewController {

    
    var indexOfRoute:Int = 0
    
    var records = [Record]()
    
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    
//    @objc func backButton() {
//        let button = PreviousPageButton(frame: CGRect(x: 20, y: 30, width: 40, height: 40))
//        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
//        view.addSubview(button)
//    }
    
    @objc func popToPreviosPage(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setUpTableView() {
        
        setNavigationBar(title: "Records")
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: TrackTableViewCell.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        tableView.backgroundColor = .B4
        
        tableView.separatorStyle = .none
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    func fetchRecords() {
        
        RecordManager.shared.fetchRecords { [weak self] result in
            switch result {
            case .success(let records):
                self?.records = records
                self?.tableView.reloadData()
            case .failure(let error): print ("fetchData Failure: \(error)")
            }
        }
    }
    
     @objc func headerRefresh() {
        
        fetchRecords()
        
        tableView.reloadData()
        
        self.tableView.mj_header?.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        
        fetchRecords()
        
        tableView.mj_header = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.backgroundColor = .B4
        // MARK: customize tarbar button
        let button = UIButton.init(type: .custom)
        //set image for button
        button.setImage(UIImage(named: "hat"), for: .normal)
        //add function for button
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        button.layer.cornerRadius = button.frame.width / 2
        button.frame = CGRect(x: 0, y: 0, width: 53, height: 51)
        //set frame
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
        
        self.tabBarController?.tabBar.isHidden = false
        
        
    }
    
}

extension TracksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            RecordManager.shared.deleteStorageRecords(fileName: records[indexPath.row].recordName) { result in
                switch result {
                case .success(_):
                    self.records.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                    
                case .failure(let error):
                    print ("delete error: \(error)")
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, sender: Any?) {
        performSegue(withIdentifier: SegueIdentifier.userRecord.rawValue, sender: records[indexPath.row])
    }
    
    
    // MARK: 傳到Detail
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.userRecord.rawValue {
            if let nextVC = segue.destination as? TrackDetailsViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                }
            }
        }
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
