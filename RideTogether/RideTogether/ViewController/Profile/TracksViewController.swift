//
//  TracksViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//
//  This used to also own its own Storage/Firestore instances and write
//  directly into the "Sharemaps" and "Routes" Firestore collections when
//  the user shared a record — bypassing RecordManager entirely and
//  duplicating a connection MapsManager already owns for reading those
//  same collections. All of that (fetching records, deleting one,
//  sharing one) now lives in TracksViewModel; this ViewController only
//  builds the table view, reacts to user actions, and reads
//  viewModel.records for its table view data source. See
//  TracksViewModel.swift for the full rationale.

import MJRefresh
import UIKit

// MARK: User Record

class TracksViewController: BaseViewController {
    var delegate: Reload?

    // Injected with a default so existing instantiation sites (from
    // Storyboard, via `init?(coder:)`) don't need to change, while tests
    // can substitute a ViewModel wired with fakes for every dependency.
    var viewModel = TracksViewModel()

    var indexOfRoute: Int = 0

    private let header = MJRefreshNormalHeader()

    private var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    func backButton() {
        let button = PreviousPageButton()
        button.tintColor = .lightGray
        view.addSubview(button)
    }

    @IBOutlet var gView: UIView! {
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed
            )
            gView.alpha = 0.85
        }
    }

    func setUpTableView() {
        setNavigationBar(title: "騎乘紀錄")

        tableView = UITableView()

        tableView.registerCellWithNib(identifier: TrackTableViewCell.identifier, bundle: nil)

        view.addSubview(tableView)

        tableView.separatorStyle = .none

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func fetchRecords() {
        viewModel.fetchRecords { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure:
                    LKProgressHUD.showFailure(text: "無法讀取資料")
                }
            }
        }
    }

    @objc func headerRefresh() {
        fetchRecords()

        tableView.mj_header?.endRefreshing()
    }

    @objc func showLongPressNotify() {
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("長按可以分享", comment: "no comment"), preferredStyle: .alert)
        let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in }
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

        setUpTableView()

        fetchRecords()

        tableView.mj_header = header

        header.setRefreshingTarget(self, refreshingAction: #selector(headerRefresh))

        backButton()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))

        tableView.addGestureRecognizer(longPress)

//        showLongPressNotify()
        setNotify()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false

        tabBarController?.tabBar.isHidden = false
    }
}

extension TracksViewController: UITableViewDelegate {
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let shareOption = UIAlertAction(title: "分享", style: .default) { [weak self] _ in
                    guard let self = self else { return }

                    self.viewModel.shareRecord(at: indexPath.row) { [weak self] result in
                        guard let self = self else { return }

                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                self.delegate?.reload()
                                LKProgressHUD.showSuccess(text: "分享成功")
                            case .failure:
                                LKProgressHUD.showFailure(text: "網路不佳，分享失敗")
                            }
                        }
                    }
                }

                let cancelOption = UIAlertAction(title: "取消", style: .default) { _ in }

                let sheet = showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [shareOption, cancelOption])

                // iPad specific code

                sheet.popoverPresentationController?.sourceView = view

                let xOrigin = view.bounds.width / 2

                let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)

                sheet.popoverPresentationController?.sourceRect = popoverRect

                sheet.popoverPresentationController?.permittedArrowDirections = .up
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        100
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        true
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteRecord(at: indexPath.row) { [weak self] result in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                        LKProgressHUD.showSuccess(text: "刪除成功")
                    case let .failure(error):
                        print("delete error: \(error)")
                        LKProgressHUD.showFailure(text: "刪除失敗")
                    }
                }
            }
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        LKProgressHUD.show()

        performSegue(withIdentifier: SegueIdentifier.userRecord.rawValue, sender: viewModel.records[indexPath.row])
    }

    // MARK: 傳到Detail

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.userRecord.rawValue {
            if let nextVC = segue.destination as? TrackDetailsViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                }
            }
        }
    }
}

extension TracksViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel.records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TrackTableViewCell = tableView.dequeueCell(for: indexPath)

        cell.setUpCell(model: viewModel.records[indexPath.row])

        return cell
    }
}
