//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import SwiftUI
import UIKit
import Combine

internal class RouteViewController: BaseViewController {
    
    let viewModel: RouteViewModel = .init()
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var dataBase = Firestore.firestore()

    private let routeCollection = Collection.routes.rawValue

    var indexOfRoute: Int = 0

    private var themeLabel = ""

    private func bindViewModel() {
        viewModel.themeLabel
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] title in
                self?.themeLabel = title
                self?.setUpThemeTag()
            })
            .store(in: &cancellables)
    }

    private let tableView: UITableView = .init()

    func setUpTableView() {
        tableView.delegate = self
        
        tableView.dataSource = self

        tableView.registerCellWithNib(identifier: RoutesTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.separatorStyle = .none

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc
    func showLongPressNotify() {
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以收藏/封鎖", comment: "no comment"), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in
        }
        sheet.addAction(okOption)
        present(sheet, animated: true, completion: nil)
    }

    func setNotify() {
        let infoButton = ButtonFactory.build(alpha: 1, imageName: "info",
                                             pointSize: 40)

        infoButton.addTarget(self, action: #selector(showLongPressNotify), for: .touchUpInside)

        self.navigationItem.setRightBarButton(UIBarButtonItem(customView: infoButton), animated: true)
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()

        setUpTableView()

        setNavigationBar(title: "探索路線")

        setNotify()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)
    }

    func setUpThemeTag() {
        let view = UIView(frame: CGRect(x: -20, y: 100, width: UIScreen.width / 2 + 10, height: 40))

        let label = UILabel(frame: CGRect(x: 20, y: 100, width: 120, height: 35))

        view.backgroundColor = .B5

        view.layer.cornerRadius = 20

        view.layer.masksToBounds = true

        label.text = themeLabel

        label.textColor = .B2

        label.textAlignment = .center

        label.font = UIFont.regular(size: 18)

        self.view.addSubview(view)

        self.view.addSubview(label)
    }

    private let saveCollection = Collection.savemaps.rawValue // Profile
    
    var userId: String { UserManager.shared.userInfo.uid }

    func uploadRecordToSavemaps(fileName: String, fileRef: String, userPhoto: String) {
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
            LKProgressHUD.show(.failure("無法收藏，因為不是使用者提供的路線"))
        }
    }

    var userPhoto: String { UserManager.shared.userInfo.pictureRef ?? "" }
}

extension RouteViewController: UITableViewDelegate {
    @objc
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let likeOption = UIAlertAction(title: "收藏", style: .default) { [self] _ in

                    self.uploadRecordToSavemaps(fileName: viewModel.routes.value[indexPath.row].routeName, fileRef: viewModel.routes.value[indexPath.row].routeMap, userPhoto: userPhoto)
                }

                let blockOption = UIAlertAction(title: "封鎖", style: .destructive) { [self] _ in

                    if userId == viewModel.routes.value[indexPath.row].uid {
                        LKProgressHUD.show(.failure("無法封鎖自己的分享紀錄"))
                    } else if viewModel.routes.value[indexPath.row].uid == nil {
                        LKProgressHUD.show(.failure("無法封鎖預設的地圖"))

                    } else {
                        UserManager.shared.blockUser(blockUserId: viewModel.routes.value[indexPath.row].uid!)

                        UserManager.shared.userInfo.blockList?.append(viewModel.routes.value[indexPath.row].uid!)
                    }
                }

                let cancelOption = UIAlertAction(title: "取消", style: .cancel) { _ in }

                showAlert(provider: .init(title: "", message: "", preferredStyle: .actionSheet, actions: [cancelOption, likeOption, blockOption]))
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        150
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        true
    }
}

extension RouteViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.routes.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: self.viewModel.routes.value[indexPath.row])

        cell.rideBtn.addTarget(self, action: #selector(goToRide), for: .touchUpInside)

        cell.rideBtn.tag = indexPath.row

        return cell
    }

    @objc
    func goToRide(_ sender: UIButton) {

        if let nextViewController = storyboard?.instantiateViewController(withIdentifier: "GoToRideViewController") as? GoToRideViewController {
            nextViewController.routes = viewModel.routes.value[sender.tag]

            navigationController?.pushViewController(nextViewController, animated: true)
        }
    }
}
