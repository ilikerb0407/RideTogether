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
    
    private var dataSource: DataSource!
    
    private var snapshot = DataSourceSnapshot()
    
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

        collectionView = UICollectionView(frame: .zero , collectionViewLayout: configureCollectionViewLayout())

        collectionView.register(Routes.self, forCellWithReuseIdentifier: "Routes")

        view.stickSubView(collectionView)

        collectionView.backgroundColor = .blue
    }
    
    func setUpButton() {
        
        let radius = UIScreen.width * 13 / 107
        
        let button = PreviousPageButton(frame: CGRect(x: 40, y: 50, width: radius, height: radius))
        
        button.addTarget(self, action: #selector(popToPreviousPage), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    func setUpThemeTag() {
        
        let view = UIView(frame: CGRect(x: 0 , y: 80, width: UIScreen.width / 2 + 10, height: 200))
        
        let label = UILabel(frame: CGRect(x: 20, y: 83, width: 120, height: 50))
        
        view.backgroundColor = .U2
        
        view.layer.cornerRadius = 20
        
        view.layer.masksToBounds = true
        
        label.text = routeLabel
        
        label.textColor = .black
        
        label.textAlignment = .center
        
        label.font = UIFont.regular(size: 18)
        
        collectionView.addSubview(view)
        
        collectionView.addSubview(label)
    }
    
   
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        
        configureDataSource()
        
        configureSnapshot()
        
        setUpButton()
        
        setUpThemeTag()
        
        navigationController?.isNavigationBarHidden = true
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: SegueIdentifier.routeList.rawValue, sender: routes[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SegueIdentifier.routeList.rawValue {
            
            if let trailInfoVC = segue.destination as? RouteRideViewController {
                
                if let trail = sender as? Route {
                    
                    trailInfoVC.routes = trail
                }
            }
        }
    }
}

extension RouteViewController {
    
    func configureDataSource() {
        
        dataSource = DataSource (
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, model) -> UICollectionViewCell? in
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Routes", for: indexPath) as? Routes
            
                cell!.setUpCell(model: model)
                            
                return cell
            })
    }
    
 
    func configureSnapshot() {
        
        snapshot.appendSections([.section])
        
        snapshot.appendItems(routes, toSection: .section)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
