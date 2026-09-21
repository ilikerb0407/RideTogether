//
//  RouteViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//
//  This used to also own its own Storage/Firestore instances and write
//  directly into the "Savemaps" Firestore collection via
//  `uploadRecordToSavemaps` — the exact same issue fixed in
//  RecommendViewController: bypassing MapsManager even though it already
//  owns reading from and deleting from that collection. Saving a route,
//  blocking its uploader, and computing the theme label now all live in
//  RouteViewModel; this ViewController only builds the table/collection
//  views, reacts to user actions, and reads viewModel.routes for its data
//  sources. See RouteViewModel.swift for the full rationale.
//
//  Note: `themeLabel` (now `viewModel.themeLabel`) is computed but never
//  actually displayed anywhere — the only code that would read it
//  (`setUpThemeTag()`) is entirely commented out below. Left in place in
//  case that UI gets wired up later; flagging it here so it isn't
//  mistaken for dead code that was missed.

import FirebaseStorage
import Lottie
import UIKit

class RouteViewController: BaseViewController {
    // Was `@IBOutlet var gView: UIView! { didSet { ... } }`. Layout
    // matches Home.storyboard's scene exactly: leading/trailing/bottom
    // pinned to the safe area, top pinned 125pt ABOVE the safe area's
    // top — bleeding upward to cover behind the custom nav bar this
    // screen sets via `setNavigationBar(title:)`.
    private lazy var gView: UIView = {
        let gradientView = UIView()
        gradientView.applyGradient(
            colors: [.white, .B3],
            locations: [0.0, 1.0], direction: .leftSkewed
        )
        gradientView.alpha = 0.85
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()

    private func setUpGradientBackground() {
        view.insertSubview(gView, at: 0)

        NSLayoutConstraint.activate([
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            gView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -125),
        ])
    }

    // MARK: - DataSource & DataSourceSnapshot typelias -

    typealias DataSource = UICollectionViewDiffableDataSource<Section, RouteModel>

    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, RouteModel>

    enum Section {
        case section
    }

    private var dataSource: DataSource!

    private var snapshot = DataSourceSnapshot()

    let routesCollectionCell = RouteCollectionCell()

    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with fakes for every dependency.
    var viewModel = RouteViewModel()

    var indexOfRoute: Int = 0

    /// Setting this from outside (HomeViewController does, via
    /// `prepare(for:sender:)`) forwards into the ViewModel and refreshes
    /// the collection view — `routes` itself isn't the source of truth
    /// anymore, `viewModel.routes` is.
    var routes: [RouteModel] {
        get { viewModel.routes }
        set {
            viewModel.updateRoutes(newValue)
            if dataSource != nil {
                configureSnapshot()
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

    @objc func popToPreviosPage(_: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }

    func setUpTableView() {
        tableView = UITableView()

        tableView.registerCellWithNib(identifier: RoutesTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.separatorStyle = .none

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())

        collectionView.lk_registerCellWithNib(identifier: "RouteCollectionCell", bundle: nil)

        view.stickSubView(collectionView)

        collectionView.backgroundColor = .clear
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

        navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpGradientBackground()

        setUpTableView()

        setNavigationBar(title: "探索路線")

        setNotify()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LKProgressHUD.dismiss()
    }

//    func setUpThemeTag() {
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.backgroundColor = .B5
//        container.layer.cornerRadius = 20
//        container.layer.masksToBounds = true
//
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = viewModel.themeLabel
//        label.textColor = .B2
//        label.textAlignment = .center
//        label.font = UIFont.regular(size: 18)
//
//        view.addSubview(container)
//        container.addSubview(label)
//
//        NSLayoutConstraint.activate([
//            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
//            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
//            container.heightAnchor.constraint(equalToConstant: 40),
//
//            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
//            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
//            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
//            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
//        ])
//
//        // If tableView exists, move it below the tag to avoid overlap
//        if let tableView = self.value(forKey: "tableView") as? UITableView {
//            // Remove existing top constraint if it anchors to safeArea top
//            // Then add a new constraint to the container's bottom
//            tableView.translatesAutoresizingMaskIntoConstraints = false
//            // Deactivate constraints that pin tableView to safeArea top
//            for c in view.constraints where (c.firstItem as? UIView) == tableView && c.firstAttribute == .top {
//                c.isActive = false
//            }
//            for c in tableView.constraints where c.firstAttribute == .top {
//                c.isActive = false
//            }
//            NSLayoutConstraint.activate([
//                tableView.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 12)
//            ])
//        }
//    }
}

extension RouteViewController: UITableViewDelegate {
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let likeOption = UIAlertAction(title: "收藏", style: .default) { [weak self] _ in
                    guard let self = self else { return }

                    self.viewModel.saveToSavemaps(at: indexPath.row) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                LKProgressHUD.showSuccess(text: "收藏成功")
                            case .failure:
                                LKProgressHUD.showFailure(text: "無法收藏，因為不是使用者提供的路線")
                            }
                        }
                    }
                }

                let blockOption = UIAlertAction(title: "封鎖", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }

                    self.viewModel.blockUploader(ofRouteAt: indexPath.row) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .failure(RouteViewModelError.cannotBlockSelf):
                                LKProgressHUD.showFailure(text: "無法封鎖自己的分享紀錄")
                            case .failure(RouteViewModelError.missingUploaderId):
                                LKProgressHUD.showFailure(text: "無法封鎖預設的地圖")
                            case .failure:
                                LKProgressHUD.showFailure(text: "封鎖失敗")
                            case .success:
                                break
                            }
                        }
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

    func tableView(_: UITableView, didSelectRowAt _: IndexPath) {}
}

//
extension RouteViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: viewModel.routes[indexPath.row])

        cell.rideBtn.addTarget(self, action: #selector(goToRide), for: .touchUpInside)

        cell.rideBtn.tag = indexPath.row

        return cell
    }

    @objc func goToRide(_ sender: UIButton) {
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "GoToRideViewController") as? GoToRideViewController {
            journeyViewController.routes = viewModel.routes[sender.tag]

            navigationController?.pushViewController(journeyViewController, animated: true)
        }
    }
}

extension RouteViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {}
}

// MARK: - CollectionView CompositionalLayout -

func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { _, env -> NSCollectionLayoutSection? in

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
            layoutSize: groupLayoutSize)
        { env -> [NSCollectionLayoutGroupCustomItem] in

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

                let cell: RouteCollectionCell = collectionView.dequeueCell(for: indexPath)

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
        snapshot = DataSourceSnapshot()

        snapshot.appendSections([.section])

        snapshot.appendItems(viewModel.routes, toSection: .section)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
