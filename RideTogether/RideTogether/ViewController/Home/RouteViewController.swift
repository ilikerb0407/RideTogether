//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import UIKit
import SwiftUI
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseFirestore
import Lottie


class RouteViewController: BaseViewController {
    
    
    
    @IBOutlet weak var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .U1],
                locations: [0.0, 2.0], direction: .leftSkewed)
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
    
    let routesCollectionCell = Routes()
    
    
    lazy var storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var dataBase = Firestore.firestore()
    
    private let routeCollection = Collection.routes.rawValue
    
    var indexOfRoute: Int = 0
    
    private var themeLabel = ""
    
    var routes = [Route]()  {
        
        didSet {
            
            setUpLabel()
        }
    }
    func setUpLabel() {
        
        if let label = routes.first?.routeTypes {
            
            switch label {
                
            case 0:
                
                themeLabel = RoutesType.recommendOne.rawValue
                
            case 1:
                
                themeLabel = RoutesType.riverOne.rawValue
                
            case 2:
                
                themeLabel = RoutesType.mountainOne.rawValue
                
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
        let button = PreviousPageButton(frame: CGRect(x: 30, y: 50, width: 40, height: 40))
        view.addSubview(button)
    }
    
    
    func setUpTableView() {

        setNavigationBar(title: "Routes")

        tableView = UITableView()

        tableView.registerCellWithNib(identifier: RoutesTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.separatorStyle = .none

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }
  
    
    private func setupCollectionView() {
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())
        
//        collectionView.registerCellWithNib(reuseIdentifier: Routes.reuseIdentifier, bundle: nil)
        
        collectionView.lk_registerCellWithNib(identifier: "Routes", bundle: nil)
        
        view.stickSubView(collectionView)
        
        collectionView.backgroundColor = .clear
    }
    
    // MARK: 新增路線資料
    func uploadRecordToDb() {
        
        let document = dataBase.collection("Routes").document()
        
        var record = Route()
        
        record.routeId = document.documentID
        
        record.routeTypes = 2
        
        record.routeInfo = ""
        
        record.routeLength = ""
        
        record.routeMap = ""
        
        record.routeName = ""
        
        do {
            
            try document.setData(from: record)
            
        } catch {
            
            print("error")
        }
        
        print("sucessfully")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setUpTableView()
        
        setupCollectionView()
        
        configureDataSource()
//
        configureSnapshot()
        
        setUpThemeTag()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        tabBarController?.tabBar.isHidden = false
        
    }
    
    func setUpThemeTag() {
        
        let view = UIView(frame: CGRect(x: -20, y: 40, width: UIScreen.width / 2 + 10, height: 40))
        
        let label = UILabel(frame: CGRect(x: 20, y: 43, width: 120, height: 35))
        
        view.backgroundColor = .U2
        
        view.layer.cornerRadius = 20
        
        view.layer.masksToBounds = true
        
        label.text = themeLabel
        
        label.textColor = .black
        
        label.textAlignment = .center
        
        label.font = UIFont.regular(size: 18)
        
        collectionView.addSubview(view)
        
        collectionView.addSubview(label)
    }
    
}

extension RouteViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "RouteRideViewController") as? RouteRideViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.routes = routes[indexPath.row]
        }

    }

}
//
extension RouteViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: self.routes[indexPath.row])

        return cell
    }

}

extension RouteViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

// MARK: - CollectionView CompositionalLayout -

func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    
    return UICollectionViewCompositionalLayout { ( _, env) -> NSCollectionLayoutSection? in
        
        let inset: CGFloat = 8
        
        let height: CGFloat = 230
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.contentInsets = NSDirectionalEdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset)
        
        let groupLayoutSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(450))
        
        let group = NSCollectionLayoutGroup.custom(
            layoutSize: groupLayoutSize) { (env) -> [NSCollectionLayoutGroupCustomItem] in
                
                let size = env.container.contentSize
                
                let itemWidth = (size.width - inset * 4) / 2
                
                return [
                    
                    NSCollectionLayoutGroupCustomItem(
                        frame: CGRect(x: (itemWidth+inset * 2), y: 0, width: itemWidth, height: height)),
                    
                    NSCollectionLayoutGroupCustomItem(
                        frame: CGRect(x: 0, y: height / 2, width: itemWidth, height: height))
                ]
            }
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.interGroupSpacing = -150
        
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
            cellProvider: { [self] (collectionView, indexPath, model) -> UICollectionViewCell? in
                
                let cell: Routes = collectionView.dequeueCell(for: indexPath)
                
                cell.setUpCell(model: model)
                
                cell.rideButton.addTarget(self, action: #selector(goToRide), for: .touchUpInside)
                
                cell.rideButton.tag = indexPath.row
                
//                cell.checkGroupButton.tag = indexPath.row
                
//                cell.checkGroupButton.addTarget(self, action: #selector(self.toGroupPage), for: .touchUpInside)
                
                return cell
            })
    }
    
    @objc func goToRide(_ sender: UIButton) {
        
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "RouteRideViewController") as? RouteRideViewController {
                    navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.routes = routes[sender.tag]
                }
    }
    
    func configureSnapshot() {
        
        snapshot.appendSections([.section])
        
        snapshot.appendItems(routes, toSection: .section)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

