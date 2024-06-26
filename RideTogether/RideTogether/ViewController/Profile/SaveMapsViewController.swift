//
//  SaveMapsViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/30.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Kingfisher
import MJRefresh
import UIKit

class SaveMapsViewController: BaseViewController {
    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
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

    @objc
    func headerRefresh() {
        fetchRecords()

        tableView.reloadData()

        self.tableView.mj_header?.endRefreshing()
    }

    // fetch uid
    func fetchRecords() {
        MapsManager.shared.fetchSavemaps { [weak self] result in
            switch result {
            case let .success(records):
                self?.records = records
                self?.tableView.reloadData()
            case let .failure(error): print("fetchData Failure: \(error)")
            }
        }
    }

    func setUptableView() {
        setNavigationBar(title: "收藏路線")

        tableView = UITableView()
        // 借用同一個tableViewcell

        tableView.registerCellWithNib(identifier: SaveMapsTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.separatorStyle = .none

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension SaveMapsViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        100
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MapsManager.shared.deleteDbRecords(recordId: records[indexPath.row].recordId) { [self] result in

                switch result {
                case .success:

                    self.records.remove(at: indexPath.row)

                    self.tableView.deleteRows(at: [indexPath], with: .left)

                case let .failure(error):

                    print("delete error: \(error)")
                }
            }
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "RideViewController") as? RideViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.record = records[indexPath.row]
        }
    }
}

extension SaveMapsViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SaveMapsTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: self.records[indexPath.row])

        cell.userPhoto.loadImage(self.records[indexPath.row].pictureRef)

        cell.userPhoto.cornerRadius = 15

        return cell
    }
}
