//
//  BaseViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import IQKeyboardManagerSwift
import MessageUI
import UIKit

internal class BaseViewController: UIViewController {

    var userInfo: UserInfo {
        get { UserManager.shared.userInfo }
        set { UserManager.shared.userInfo = newValue }
    }

    private var isDisplayingLocationServicesDenied: Bool = false

    func displayLocationServicesDisabledAlert() {
        let settingsAction = UIAlertAction(title: "設定", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:])
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let alertProvider = AlertProvider(title: "無法讀取位置", message: "請開啟定位服務", preferredStyle: .alert, actions: [settingsAction, cancelAction])
        showAlert(provider: alertProvider)
    }

    func displayLocationServicesDeniedAlert() {
        guard !isDisplayingLocationServicesDenied else { return }
        displayLocationServicesDisabledAlert()
        isDisplayingLocationServicesDenied = false
    }
    
    static var identifier: String {
        String(describing: self)
    }

    var isHideNavigationBar: Bool {
        false
    }

    var isEnableIQKeyboard: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarAndKeyboardState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateNavigationBarAndKeyboardState()
    }

    private func updateNavigationBarAndKeyboardState() {
        if isHideNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
        IQKeyboardManager.shared.isEnabled = isEnableIQKeyboard
        self.setNeedsStatusBarAppearanceUpdate()
    }

    @objc
    func popToPreviousPage(_: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    func showBlockAlertAction(uid: String) {
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let blockAction = UIAlertAction(title: "封鎖", style: .destructive) { _ in
            UserManager.shared.blockUser(blockUserId: uid)
            UserManager.shared.userInfo.blockList?.append(uid)
        }
        let alertProvider = AlertProvider(title: "封鎖用戶", message: "您將無法看見該用戶的訊息及揪團", preferredStyle: .alert, actions: [cancelAction, blockAction])
        showAlert(provider: alertProvider)
    }

    
    func setNavigationBar(title: String) {
        self.title = title
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let button = ButtonFactory.build(backgroundColor: .B5 ?? .white,
                                             tintColor: .B2 ?? .white,
                                             cornerRadius: 20,
                                             imageName: "chevron.left",
                                             weight: .light, pointSize: 40)
        button.addTarget(self, action: #selector(popToPreviousPage), for: .touchUpInside)
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: button), animated: true)
    }

    private func presentViewController(_ navBar: UINavigationController) {
        if #available(iOS 15.0, *) {
            navBar.sheetPresentationController?.detents = [.large()]
        }
        self.navigationController?.present(navBar, animated: true, completion: nil)
    }
}

extension BaseViewController: UIGestureRecognizerDelegate {}
