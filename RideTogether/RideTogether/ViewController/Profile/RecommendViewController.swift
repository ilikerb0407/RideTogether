//
//  RecommendViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import UIKit
import MJRefresh
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift


// MARK: Recommend-Route
class RecommendViewController: BaseViewController {

    var records = [Record]()
    
    private let header = MJRefreshNormalHeader()
    
    private let tableViewCell = RecommendTableViewCell()
    
    private let saveCollection = Collection.savemaps.rawValue // Profile
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    lazy var storage = Storage.storage()
    
    lazy var storageRef = storage.reference()
    
    lazy var dataBase = Firestore.firestore()

    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    func setUpTableView() {
        
        setNavigationBar(title: "分享牆")
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: RecommendTableViewCell.identifier, bundle: nil)
        
        view.addSubview(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.separatorStyle = .none
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    func uploadRecordToSavemaps(fileName: String, fileURL: URL) {
        
        let document = dataBase.collection(saveCollection).document()
        
        var record = Record()
        
        record.uid = userId
        
        record.recordId = document.documentID
        
        record.recordName = fileName
        
        record.recordRef = fileURL.absoluteString
        
        do {
            
            try document.setData(from: record)
            
        } catch {
            
            print("error")
        }
        
        print("sucessfully")
    }

    
    func fetchRecords() {
        
        MapsManager.shared.fetchRecords { [weak self] result in
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
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
}

extension RecommendViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
       
            if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "FollowJourneyViewController") as? FollowJourneyViewController {
                navigationController?.pushViewController(journeyViewController, animated: true)
                journeyViewController.record = records[indexPath.row]
                // 這一頁宣告的變數, 是下一頁的變數 (可以改用closesure傳看看)
            }
        
    }
    
    
//        let recordRef = storageRef.child("records").child("\(userId)")
//        //  gs://bikeproject-59c89.appspot.com/records
//        let spaceRef = recordRef.child(records[indexPath.row].recordName)
//
//
//        spaceRef.downloadURL { [self] result in
//            switch result {
//            case .success(let url) :
////                    completion(.success(url))
//                print ("\(url)")
//                self.uploadRecordToSavemaps(fileName: records[indexPath.row].recordName, fileURL: url)
//                //
//            case .failure(let error) :
////                    completion(.failure(error))
//                print ("\(error)")
//            }
//        }

    
   
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == SegueIdentifier.recommendMaps.rawValue {
//            if let nextVC = segue.destination as? RecommendDetailViewController {
//                if let record = sender as? Record {
//                    nextVC.record = record
//                }
//            }
//        }
//    }
   
}

extension RecommendViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: RecommendTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(model: self.records[indexPath.row])
        
        return cell
    }
}

