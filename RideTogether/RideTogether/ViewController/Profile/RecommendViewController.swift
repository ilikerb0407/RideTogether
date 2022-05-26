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
import Lottie
import SwiftUI
import Kingfisher


// MARK: Recommend-Route
class RecommendViewController: BaseViewController {
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.85
        }
    }
    
    
    var records = [Record]()
    
    private let header = MJRefreshNormalHeader()
    
    private let tableViewCell = RecommendTableViewCell()
    
    private let saveCollection = Collection.savemaps.rawValue // Profile
    
    var userId: String { UserManager.shared.userInfo.uid }
    
    var userPhoto: String { UserManager.shared.userInfo.pictureRef ?? "" }
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    
//    @objc var savemaps: [String] {UserManager.shared.userInfo.saveMaps ?? [""]}
    
    lazy var storage = Storage.storage()
    
    lazy var storageRef = storage.reference()
    
    lazy var dataBase = Firestore.firestore()
    
//    func setUpPhoto(userInfo: UserInfo) {
//
//        tableViewCell.userPhoto.loadImage(userInfo.pictureRef)
//
//        tableViewCell.userPhoto.cornerRadius = 25
//
//    }
    
    
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
    
    func uploadRecordToSavemaps(fileName: String, fileRef: String, userPhoto: String ) {
        
        let document = dataBase.collection(saveCollection).document()
        
        var record = Record()
        
        record.uid = userId
        
        record.recordId = document.documentID
        
        record.recordName = fileName
        
        record.recordRef = fileRef
        
        record.pictureRef = userPhoto
        
        do {
            
            try document.setData(from: record)
            
        } catch {
            
            LKProgressHUD.showFailure(text: "無法收藏，因為不是使用者提供的路線")
            print("error")
        }
        
        print("sucessfully")
    }
    
    
    
    func fetchRecords() {
        
        MapsManager.shared.fetchRecords { [weak self] result in
            
            switch result {
                
            case .success(let records):
                
                var filtermaps = [Record]()
                
                for maps in records where self?.userInfo.blockList?.contains(maps.uid) == false {
                    
                    filtermaps.append(maps)
                }
                
                self?.records = filtermaps
                
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
    
    @objc func showLongPressNotify() {
        
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以收藏/封鎖", comment: "no comment"), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in
            }
        sheet.addAction(okOption)
        present(sheet, animated: true, completion: nil)
        
    }
    
    func setNotify() {
        
        
        let rightButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        let infoImage = UIImage(systemName: "info")
        
        rightButton.setImage(infoImage, for: .normal)
        
        rightButton.addTarget(self, action: #selector(showLongPressNotify), for: .touchUpInside)
        
        self.navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUpTableView()
        
        fetchRecords()
        
        tableView.mj_header = header
        
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        
        tableView.addGestureRecognizer(longPress)
        
//        showLongPressNotify()
        
        setNotify()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        self.tabBarController?.tabBar.isHidden = false
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

extension RecommendViewController: UITableViewDelegate {
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                 let likeOption = UIAlertAction(title: "收藏", style: .default) { [self] _ in
                    
                    
                    self.uploadRecordToSavemaps(fileName: records[indexPath.row].recordName, fileRef: records[indexPath.row].recordRef, userPhoto: records[indexPath.row].pictureRef ?? "")

                        waitlottie.isHidden = true
                }
                
                let blockOption = UIAlertAction(title: "封鎖", style: .destructive) { [self] _ in
                    
                    UserManager.shared.blockUser(blockUserId: records[indexPath.row].uid)

                    UserManager.shared.userInfo.blockList?.append(records[indexPath.row].uid)
                    
                    self.fetchRecords()
                    
                    self.waitlottie.isHidden = true
                }
                
                let cancelOption = UIAlertAction(title: "取消", style: .cancel){ _ in
                    self.waitlottie.isHidden = true
                }
                
                showAlertAction(title: nil, message: nil, actions: [cancelOption, likeOption, blockOption])
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        LKProgressHUD.show()
        
        if let nextViewController = storyboard?.instantiateViewController(withIdentifier: "RideViewController") as? RideViewController {
            navigationController?.pushViewController(nextViewController, animated: true)
            nextViewController.record = records[indexPath.row]
            
        }
        
    }
    
}

extension RecommendViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: RecommendTableViewCell = tableView.dequeueCell(for: indexPath)
        
        cell.setUpCell(model: self.records[indexPath.row])
        
        cell.userPhoto.loadImage(self.records[indexPath.row].pictureRef)

        cell.userPhoto.cornerRadius = 15
            
        return cell
    }
    
}
