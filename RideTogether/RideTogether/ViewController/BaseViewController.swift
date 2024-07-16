//
//  BaseViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import IQKeyboardManagerSwift
import MessageUI
import UIKit


class BaseViewController: UIViewController, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate {

    private var userInfo: UserInfo { UserManager.shared.userInfo }

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

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
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
        IQKeyboardManager.shared.enable = isEnableIQKeyboard
        self.setNeedsStatusBarAppearanceUpdate()
    }

    @objc
    func popToPreviousPage(_: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissVC() {
        dismiss(animated: true, completion: nil)
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
        let leftButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: leftButton), animated: true)
    }

    @objc
    func showBikeViewController() {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "UBikeViewController") as? UBikeViewController {
            let navBar = UINavigationController(rootViewController: rootVC)
            presentViewController(navBar)
        } else {
            LKProgressHUD.show(.failure("目前僅提供台北市Ubike"))
        }
    }

    @objc
    func presentRouteSelectionViewController() {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "RouteSelectionViewController") as? RouteSelecViewController {
            let navBar = UINavigationController(rootViewController: rootVC)
            presentViewController(navBar)
        } else {
            LKProgressHUD.show(.failure("網路問題，無法跳出"))
        }
    }

    private func presentViewController(_ navBar: UINavigationController) {
        if #available(iOS 15.0, *) {
            navBar.sheetPresentationController?.detents = [.large()]
        }
        self.navigationController?.present(navBar, animated: true, completion: nil)
    }

    func push(withIdentifier: String) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: withIdentifier) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}


