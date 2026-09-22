//
//  RecommendViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//
//  This used to also own its own Storage/Firestore instances and write
//  directly into the "Savemaps" Firestore collection when the user saved
//  a shared record — bypassing MapsManager entirely, even though
//  MapsManager already owns reading from and deleting from that same
//  collection. Fetching records (with block-list filtering), saving one,
//  and blocking its uploader now all live in RecommendViewModel; this
//  ViewController only builds the table view, reacts to user actions,
//  and reads viewModel.records for its table view data source. See
//  RecommendViewModel.swift for the full rationale, including a
//  block-list filtering bug fixed along the way.

import Lottie
import MJRefresh
import UIKit

class RecommendViewController: BaseViewController {

    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with fakes for every dependency.
    var viewModel = RecommendViewModel()

    private let header = MJRefreshNormalHeader()

    private let tableViewCell = RecommendTableViewCell()

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
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
            gView.topAnchor.constraint(equalTo: view.topAnchor),
            gView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            gView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func setUpTableView() {
        setNavigationBar(title: "分享牆")

        tableView = UITableView()

        tableView.registerCellWithNib(identifier: RecommendTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.backgroundColor = .clear

        tableView.separatorStyle = .none

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func fetchRecords() {
        viewModel.fetchRecords { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.tableView.reloadData()
                case let .failure(error):
                    print("fetchData Failure: \(error)")
                }
            }
        }
    }

    @objc func headerRefresh() {
        fetchRecords()

        tableView.mj_header?.endRefreshing()
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

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpGradientBackground()
        
        setUpTableView()

        fetchRecords()

        tableView.mj_header = header

        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)

        setNotify()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false

        tabBarController?.tabBar.isHidden = false
    }
}

extension RecommendViewController: UITableViewDelegate {
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let likeOption = UIAlertAction(title: "收藏", style: .default) { [weak self] _ in
                    guard let self = self else { return }

                    self.viewModel.saveToSavemaps(at: indexPath.row) { [weak self] result in
                        guard let self = self else { return }

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

                    self.viewModel.blockUploader(ofRecordAt: indexPath.row) { [weak self] result in
                        guard let self = self else { return }

                        DispatchQueue.main.async {

                            switch result {
                            case .success:
                                self.fetchRecords()
                            case .failure(RecommendViewModelError.cannotBlockSelf):
                                LKProgressHUD.showFailure(text: "無法封鎖自己的分享紀錄")
                            case .failure:
                                LKProgressHUD.showFailure(text: "封鎖失敗")
                            }
                        }
                    }
                }

                let cancelOption = UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
                    
                }
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        100
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        LKProgressHUD.show()

        if let nextViewController = storyboard?.instantiateViewController(withIdentifier: "RideViewController") as? RideViewController {
            navigationController?.pushViewController(nextViewController, animated: true)
            nextViewController.record = viewModel.records[indexPath.row]
        }
    }
}

extension RecommendViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RecommendTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: viewModel.records[indexPath.row])

        cell.userPhoto.loadImage(viewModel.records[indexPath.row].pictureRef)

        cell.userPhoto.cornerRadius = 15

        return cell
    }
}
