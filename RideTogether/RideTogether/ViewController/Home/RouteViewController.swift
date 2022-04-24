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
    private var themeLabel = ""
    
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
    
    private func setupCollectionView() {

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())

        collectionView.register(Routes.self, forCellWithReuseIdentifier: "Routes")

        view.stickSubView(collectionView)

        collectionView.backgroundColor = .clear
    }
    
    func setUpButton() {
        
        let radius = UIScreen.width * 13 / 107
        
        let button = PreviousPageButton(frame: CGRect(x: 40, y: 50, width: radius, height: radius))
        
        button.addTarget(self, action: #selector(popToPreviousPage), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
   
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
    }
    
    // MARK: - CollectionView CompositionalLayout -

    func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        
        return UICollectionViewCompositionalLayout { ( _, env) -> NSCollectionLayoutSection? in
            
            let inset: CGFloat = 8
            
            let height: CGFloat = 270
            
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
}

extension RouteViewController: UICollectionViewDelegate {
    
}
