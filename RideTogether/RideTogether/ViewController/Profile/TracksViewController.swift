//
//  TracksViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import CoreGPX
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import MJRefresh
import SwiftUI
import UIKit

// MARK: User Record

class TracksViewController: BaseViewController {
    lazy var storage = Storage.storage()

    lazy var storageRef = storage.reference()

    lazy var dataBase = Firestore.firestore()

    private let sharedRecordsCollection = Collection.sharedmaps.rawValue

    private let routeCollection = Collection.routes.rawValue // Home

    var indexOfRoute: Int = 0

    var records = [Record]()

    var userId: String { UserManager.shared.userInfo.uid }

    var userPhoto: String { UserManager.shared.userInfo.pictureRef ?? "" }

    var userName: String { UserManager.shared.userInfo.userName ?? "" }

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

    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
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

            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func fetchRecords() {
        RecordManager.shared.fetchRecords { [weak self] result in
            switch result {
            case let .success(records):
                self?.records = records
                self?.tableView.reloadData()
            case .failure:
                LKProgressHUD.show(.failure("無法讀取資料"))
            }
        }
    }

    @objc
    func headerRefresh() {
        fetchRecords()

        tableView.reloadData()

        self.tableView.mj_header?.endRefreshing()
    }

    @objc
    func showLongPressNotify() {
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以分享", comment: "no comment"), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in }
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

        backButton()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)

//        showLongPressNotify()
        setNotify()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false

        tabBarController?.tabBar.isHidden = false
    }

    func recordmanager() -> RecordManager {
        RecordManager.shared
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        recordmanager().track(event: "viewDidAppear - \(type(of: self))")
    }
}

extension TracksViewController: UITableViewDelegate {
    @objc
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let shareOption = UIAlertAction(title: "分享", style: .default) { [self] _ in

                    let recordRef = storageRef.child("records").child("\(userId)")
                    //  gs://bikeproject-59c89.appspot.com/records
                    let spaceRef = recordRef.child(records[indexPath.row].recordName)

                    spaceRef.downloadURL { [self] result in
                        switch result {
                        case let .success(url):
                            //                    completion(.success(url))

                            self.uploadRecordToDb(fileName: records[indexPath.row].recordName, fileURL: url)

                            self.uploadRecordToPopular(fileName: records[indexPath.row].recordName, fileURL: url, userPhoto: userPhoto)

                            LKProgressHUD.show(.success( "分享成功"))

                        case let .failure(error):
//                            completion(.failure(error))
                            LKProgressHUD.show(.failure( "網路不佳，分享失敗"))
                        }
                    }
                }

                let cancelOption = UIAlertAction(title: "取消", style: .default) { _ in }

                showAlert(provider: .init(title: "", message: "", preferredStyle: .actionSheet, actions: [shareOption, cancelOption]))
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        100
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        true
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            RecordManager.shared.deleteStorageRecords(fileName: records[indexPath.row].recordName) { result in
                switch result {
                case .success:
                    self.records.remove(at: indexPath.row)

                    self.tableView.deleteRows(at: [indexPath], with: .left)

                    LKProgressHUD.show(.success("刪除成功"))

                case let .failure(error):
                    LKProgressHUD.show(.failure("刪除失敗，失敗原因:\(error)"))
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

        record.routeTypes = 0

        do {
            try document.setData(from: record)

        } catch {
            LKProgressHUD.show(.failure("新增資料失敗"))
        }

        LKProgressHUD.show(.success("新增資料成功"))
    }

    func uploadRecordToPopular(fileName: String, fileURL: URL, userPhoto: String) {
        let document = dataBase.collection(routeCollection).document()

        var route = Route()

        route.uid = userId

        route.routeId = document.documentID

        route.routeName = fileName

        route.routeMap = fileURL.absoluteString

        route.routeInfo = "\(userName) 分享了路線"

        route.pictureRef = userPhoto

        let inputURL = fileURL

        guard let gpx = GPXParser(withURL: inputURL)?.parsedData() else {
            return
        }

        let length = gpx.tracksLength

        route.routeLength = "距離 : \(length.toDistance())"

        route.routeTypes = 0

        do {
            try document.setData(from: route)

        } catch {
            LKProgressHUD.show(.failure("新增資料失敗"))
        }

        LKProgressHUD.show(.success("新增資料成功"))
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: SegueIdentifier.userRecord.rawValue, sender: records[indexPath.row])
    }

    // MARK: 傳到Detail
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.userRecord.rawValue {
            if let nextVC = segue.destination as? TrackInfoViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                }
            }
        }
    }
}

extension TracksViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TrackTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: self.records[indexPath.row])

        return cell
    }
}
