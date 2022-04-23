//
//  TracksViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import UIKit
import MJRefresh
import SwiftUI
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore


//MARK: User Record

class TracksViewController: BaseViewController {
    
    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var dataBase = Firestore.firestore()
    private let sharedRecordsCollection = Collection.sharedmaps.rawValue
    
    var indexOfRoute:Int = 0
    
    var records = [Record]()
    
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
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .orange],
                locations: [0.0, 3.0], direction: .leftSkewed)
//            gView.alpha = 0.85
            // 不會把資料覆蓋住
        }
        
    }
    
    func setUpTableView() {
        
        setNavigationBar(title: "Records")
        
        tableView = UITableView()
        
        tableView.registerCellWithNib(identifier: TrackTableViewCell.identifier, bundle: nil)
        
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
        tabBarController?.tabBar.isHidden = false
        
        
    }
    
}

extension TracksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            RecordManager.shared.deleteStorageRecords(fileName: records[indexPath.row].recordName) { result in
//                switch result {
//                case .success(_):
//                    self.records.remove(at: indexPath.row)
//                    self.tableView.deleteRows(at: [indexPath], with: .left)
//
//                case .failure(let error):
//                    print ("delete error: \(error)")
//                }
//            }
//        }
//    }
    func uploadRecordToDb(fileName: String, fileURL: URL) {
        
        let document = dataBase.collection(sharedRecordsCollection).document()
        
        var record = Record()
        
//        record.uid = userId
        
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
   
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sheet = UIAlertController.init(title: "What do you want", message: "", preferredStyle: .alert)
        let detailOption = UIAlertAction(title: "Show Detail", style: .default) { [self] _ in
            performSegue(withIdentifier: SegueIdentifier.userRecord.rawValue, sender: records[indexPath.row])
        }
        
        let shareOption = UIAlertAction(title: "Share to friends", style: .default) { [self] _ in
//            self.shareGPXDataToFriends(indexPath.row, tableView: tableView, cellForRowAt: indexPath)
            let recordRef = storageRef.child("records")
            //  gs://bikeproject-59c89.appspot.com/records
            let spaceRef = recordRef.child(records[indexPath.row].recordName)
            spaceRef.downloadURL { result in
                switch result {
                case .success(let url) :
//                    completion(.success(url))
                    
                    self.uploadRecordToDb(fileName: records[indexPath.row].recordName, fileURL: url)
                case .failure(let error) :
//                    completion(.failure(error))
                    print ("\(error)")
                }
            }
  
        }
        
        let removeOption = UIAlertAction(title: "Delete it", style: .destructive) { [self] _ in
            
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
        let cancelOption = UIAlertAction(title: "cancel", style: .cancel){ _ in }
        
        sheet.addAction(detailOption)
        sheet.addAction(shareOption)
        sheet.addAction(removeOption)
        sheet.addAction(cancelOption)
        
        present(sheet, animated: true, completion: nil)
        
        
//        performSegue(withIdentifier: SegueIdentifier.userRecord.rawValue, sender: records[indexPath.row])
        
    }
    
//    func shareGPXDataToFriends(_ rowIndex: Int, tableView: UITableView, cellForRowAt indexPath: IndexPath) {}
        
        
        
        // MARK: 傳簡訊的方式 UIActivityViewController
        
//        let activityViewController = UIActivityViewController(activityItems: [gpxFileInfp.fileURL], applicationActivities: nil)
//
//        var cellRect = tableView.rectForRow(at: indexPath)
//        cellRect.origin = CGPoint(x: 0, y: 0) // origin must be at 0 or sheet will display offset due to height of cell
//
//        activityViewController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
//        activityViewController.popoverPresentationController?.sourceRect = cellRect
//
//        // NOTE: As the activity view controller can be quite tall at times,
//        //       the display of it may be offset automatically at times to ensure the activity view popup fits the screen.
//
//        activityViewController.completionWithItemsHandler = {
//            (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
//            if !completed {
//                // User canceled
//                print("actionShareAtIndex: Cancelled")
//                return
//            }
//            // User completed activity
//            print("actionShareFileAtIndex: User completed activity")
//        }
//
//       present(activityViewController, animated: true, completion: nil)
    
    
    
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
