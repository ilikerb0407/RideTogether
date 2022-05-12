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
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    var userPhoto: String { UserManager.shared.userInfo.pictureRef ?? "" }
    
    private let header = MJRefreshNormalHeader()
    
    private var tableView: UITableView! {
        
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
      func backButton() {
            let button = PreviousPageButton()
          button.tintColor = .lightGray
            view.addSubview(button)
        }
    
    @IBOutlet weak var gView: UIView! {
        
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
       
        }
        
    }
    
    func setUpTableView() {
        
        setNavigationBar(title: "騎乘紀錄")
        
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
            
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
    
    func showLongPressNotify() {
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以分享", comment: "no comment"), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in
            }
        sheet.addAction(okOption)
        present(sheet, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        
        fetchRecords()
        
        tableView.mj_header = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        
        backButton()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        
        tableView.addGestureRecognizer(longPress)
        
//        showLongPressNotify()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        tabBarController?.tabBar.isHidden = false
        
        
    }
    
}

extension TracksViewController: UITableViewDelegate {
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                let shareOption = UIAlertAction(title: "分享", style: .default) { [self] _ in
                    
                    let recordRef = storageRef.child("records").child("\(userId)")
                    //  gs://bikeproject-59c89.appspot.com/records
                    let spaceRef = recordRef.child(records[indexPath.row].recordName)

                    spaceRef.downloadURL { [self] result in
                        switch result {
                        case .success(let url) :
        //                    completion(.success(url))
                            print ("\(url)")
                            self.uploadRecordToDb(fileName: records[indexPath.row].recordName, fileURL: url)
                            //
                            LKProgressHUD.dismiss()
                        case .failure(let error) :
        //                    completion(.failure(error))
                            print ("\(error)")
                        }
                    }
                }
                
                let cancelOption = UIAlertAction(title: "取消", style: .default) { _ in }
                
                let sheet = showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [ shareOption,cancelOption])
                
                // iPad specific code
                
                sheet.popoverPresentationController?.sourceView = self.view
                        
                let xOrigin = self.view.bounds.width / 2
                
                let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)
                    
                sheet.popoverPresentationController?.sourceRect = popoverRect
                        
                sheet.popoverPresentationController?.permittedArrowDirections = .up
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
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
    
    func uploadRecordToDb(fileName: String, fileURL: URL) {
        
        let document = dataBase.collection(sharedRecordsCollection).document()
        
        var record = Record()
        
        record.uid = userId
        
        record.recordId = document.documentID
        
        record.recordName = fileName
        
        record.recordRef = fileURL.absoluteString
        
        record.pictureRef = userPhoto
        
        do {
            
            try document.setData(from: record)
            
        } catch {
            
            print("error")
        }
        
        print("sucessfully")
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        LKProgressHUD.show()
        
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
