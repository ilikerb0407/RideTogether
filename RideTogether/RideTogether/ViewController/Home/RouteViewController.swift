//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Lottie
import SwiftUI
import UIKit

class RouteViewController: BaseViewController {
    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    // MARK: - DataSource & DataSourceSnapshot typelias -

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Route>

    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Route>

    enum Section {
        case section
    }

    private var dataSource: DataSource!

    private var snapshot = DataSourceSnapshot()

    let routesCollectionCell = RoutesCollectionViewCell()

    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var dataBase = Firestore.firestore()

    private let routeCollection = Collection.routes.rawValue

    var indexOfRoute: Int = 0

    private var themeLabel = ""

    var routes = [Route]() {
        didSet {
            setUpLabel()
        }
    }

    func setUpLabel() {
        if let label = routes.first?.routeTypes {
            switch label {
            case 0:

                themeLabel = RoutesTypeTest.userOne.title

            case 1:

                themeLabel = RoutesTypeTest
                    .recommendOne.title

            case 2:

                themeLabel = RoutesTypeTest.riverOne.title

            case 3:

                themeLabel = RoutesTypeTest.mountainOne.title

            default:
                return
            }
        }
    }

    private var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
        }
    }

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    func backButton() {
        let button = PreviousPageButton(frame: CGRect(x: 20, y: 30, width: 40, height: 40))
        button.backgroundColor = .B5
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc
    func popToPreviosPage(_: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }

    func setUpTableView() {
        tableView = UITableView()

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

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())

//        collectionView.registerCellWithNib(reuseIdentifier: Routes.reuseIdentifier, bundle: nil)

        collectionView.lk_registerCellWithNib(identifier: "RoutesCollectionViewCell", bundle: nil)

        view.stickSubView(collectionView)

        collectionView.backgroundColor = .clear
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
        let rightButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        let infoImage = UIImage(systemName: "info")

        rightButton.setImage(infoImage, for: .normal)

        rightButton.addTarget(self, action: #selector(showLongPressNotify), for: .touchUpInside)

        self.navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()

        setNavigationBar(title: "探索路線")

        setNotify()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)

        setUpThemeTag()
    }

    func setUpThemeTag() {
        let view = UIView(frame: CGRect(x: -20, y: 80, width: UIScreen.width / 2 + 10, height: 40))

        let label = UILabel(frame: CGRect(x: 20, y: 80, width: 120, height: 35))

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
            LKProgressHUD.showFailure(text: "無法收藏，因為不是使用者提供的路線")
            print("error")
        }

        print("sucessfully")
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

                    self.uploadRecordToSavemaps(fileName: routes[indexPath.row].routeName, fileRef: routes[indexPath.row].routeMap, userPhoto: userPhoto)
                }

                let blockOption = UIAlertAction(title: "封鎖", style: .destructive) { [self] _ in

                    if userId == routes[indexPath.row].uid {
                        LKProgressHUD.showFailure(text: "無法封鎖自己的分享紀錄")
                    } else if routes[indexPath.row].uid == nil {
                        LKProgressHUD.showFailure(text: "無法封鎖預設的地圖")

                    } else {
                        UserManager.shared.blockUser(blockUserId: routes[indexPath.row].uid!)

                        UserManager.shared.userInfo.blockList?.append(routes[indexPath.row].uid!)
                    }
                }

                let cancelOption = UIAlertAction(title: "取消", style: .cancel) { _ in }

                showAlertAction(title: nil, message: nil, actions: [cancelOption, likeOption, blockOption])
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
        routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: self.routes[indexPath.row])

        cell.rideBtn.addTarget(self, action: #selector(goToRide), for: .touchUpInside)

        cell.rideBtn.tag = indexPath.row

        return cell
    }

    @objc
    func goToRide(_ sender: UIButton) {
        print("time1:\(CFAbsoluteTimeGetCurrent())")
        LKProgressHUD.show()

        if let nextViewController = storyboard?.instantiateViewController(withIdentifier: "GoToRideViewController") as? GoToRideViewController {
            nextViewController.routes = routes[sender.tag]

            navigationController?.pushViewController(nextViewController, animated: true)
        }
    }
}

extension RouteViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) { }
}

// MARK: - CollectionView CompositionalLayout -

func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { _, env -> NSCollectionLayoutSection? in

        let inset: CGFloat = 8

        let height: CGFloat = 230

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        item.contentInsets = NSDirectionalEdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        )

        let groupLayoutSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(450)
        )

        let group = NSCollectionLayoutGroup.custom(
            layoutSize: groupLayoutSize) { env -> [NSCollectionLayoutGroupCustomItem] in

                let size = env.container.contentSize

                let itemWidth = (size.width - inset * 4) / 2

                return [
                    // 右邊的 group item
                    NSCollectionLayoutGroupCustomItem(
                        frame: CGRect(x: itemWidth + inset * 2, y: 0, width: itemWidth, height: height)),
                    // 左邊的 group item
                    NSCollectionLayoutGroupCustomItem(
                        frame: CGRect(x: 0, y: height / 2, width: itemWidth, height: height)),
                ]
            }

        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = -180

        section.contentInsets = NSDirectionalEdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        )

        return section
    }
}

// MARK: - CollectionView Diffable Data Source -

extension RouteViewController {
    func configureDataSource() {
        dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { [self] collectionView, indexPath, model -> UICollectionViewCell? in

                let cell: RoutesCollectionViewCell = collectionView.dequeueCell(for: indexPath)

                cell.setUpCell(model: model)

//                cell.rideButton.addTarget(self, action: #selector(goToRide), for: .touchUpInside)

                cell.rideButton.tag = indexPath.row

//                cell.checkGroupButton.tag = indexPath.row

//                cell.checkGroupButton.addTarget(self, action: #selector(self.toGroupPage), for: .touchUpInside)

                return cell
            }
        )
    }

    func configureSnapshot() {
        snapshot.appendSections([.section])

        snapshot.appendItems(routes, toSection: .section)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
