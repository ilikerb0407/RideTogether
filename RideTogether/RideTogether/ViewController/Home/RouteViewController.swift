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

    private var tableView: UITableView!
    
    // ViewModel 注入
    var viewModel = RouteViewModel()

    // 對外暴露的介面：外部傳入資料時直接餵給 ViewModel
    var routes: [RouteModel] {
        get { viewModel.routes }
        set { viewModel.updateRoutes(newValue) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpGradientBackground()
        setUpTableView()
        setNavigationBar(title: "探索路線")
        setNotify()
        setupViewModelBinding()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LKProgressHUD.dismiss()
    }

    // MARK: - MVVM Binding
    private func setupViewModelBinding() {
        // 當 ViewModel 的資料改變時，自動刷新 TableView
        viewModel.onRoutesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - UI Setup
    private func setUpGradientBackground() {
        view.insertSubview(gView, at: 0)
        NSLayoutConstraint.activate([
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            gView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -125),
        ])
    }

    private func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellWithNib(identifier: RoutesTableViewCell.identifier, bundle: nil)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setNotify() {
        let rightButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.setImage(UIImage(systemName: "info"), for: .normal)
        rightButton.addTarget(self, action: #selector(showLongPressNotify), for: .touchUpInside)
        navigationItem.setRightBarButton(UIBarButtonItem(customView: rightButton), animated: true)
    }

    @objc private func showLongPressNotify() {
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以收藏/封鎖", comment: ""), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel)
        sheet.addAction(okOption)
        present(sheet, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension RouteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("目前路線數量: \(viewModel.numberOfItems)") // 👈 檢查這裡印出多少
        return viewModel.numberOfItems
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("正在渲染第 \(indexPath.row) 筆資料") // 👈 檢查這裡有沒有印出
        let cell: RoutesTableViewCell = tableView.dequeueCell(for: indexPath)
        
        if let model = viewModel.route(at: indexPath.row) {
            cell.setUpCell(model: model)
        }

        cell.rideBtn.tag = indexPath.row
        cell.rideBtn.addTarget(self, action: #selector(goToRide), for: .touchUpInside)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }

    @objc private func goToRide(_ sender: UIButton) {
        guard let routeModel = viewModel.route(at: sender.tag) else { return }
        
        let journeyViewController = GoToRideViewController()
        journeyViewController.routes = routeModel
        navigationController?.pushViewController(journeyViewController, animated: true)
    }

    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        let touchPoint = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }

        let likeOption = UIAlertAction(title: "收藏", style: .default) { [weak self] _ in
            self?.viewModel.saveToSavemaps(at: indexPath.row) { result in
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
            self?.viewModel.blockUploader(ofRouteAt: indexPath.row) { result in
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

        let cancelOption = UIAlertAction(title: "取消", style: .cancel)
        showAlertAction(title: nil, message: nil, actions: [cancelOption, likeOption, blockOption])
    }
}
