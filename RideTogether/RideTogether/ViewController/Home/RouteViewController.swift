//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import UIKit

class RouteViewController: BaseViewController {
    
    // MARK: - DataSource & DataSourceSnapshot typelias -
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Route>
    
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Route>
    
    // MARK: - Class Properties -
    
    enum Section {
        
        case section
    }
    
    
    var routes = [Route]() {
        didSet {
            setUpLabel()
        }
    }
    
    private var routeLabel = ""
    
    func setUpLabel() {
        
        if let label = routes.first?.routeTypes {
            
            switch label {
                
            case 0:
                
                routeLabel = RoutesType.recommendOne.rawValue
                
            case 1:
                
                routeLabel = RoutesType.riverOne.rawValue
                
            case 2:
                
                routeLabel = RoutesType.mountainOne.rawValue
                
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
    
//    private func setupCollectionView() {
//
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())
//
//        collectionView.registerCellWithNib(reuseIdentifier: RoutesType.reuseIdentifier, bundle: nil)
//
//        view.stickSubView(collectionView)
//
//        collectionView.backgroundColor = .clear
//    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

//        setupCollectionView()
    }
    
}

extension RouteViewController: UICollectionViewDelegate {
    
}
