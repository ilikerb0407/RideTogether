//
//  BaseViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import IQKeyboardManagerSwift
import Kingfisher
import MessageUI
import Lottie


class BaseViewController: UIViewController, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate {
    
    let stopWatch = StopWatch()
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    func displayLocationServicesDisabledAlert() {
        
        let settingsAction = UIAlertAction(title: "設定", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                
                UIApplication.shared.open(url, options: [:])
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        showAlertAction(title: "無法讀取位置", message: "請開啟定位服務", actions: [settingsAction, cancelAction])
        
    }
    
    func displayLocationServicesDeniedAlert() {
        
        if isDisplayingLocationServicesDenied { return }
        
        let settingsAction = UIAlertAction(title: "設定",
                                           style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:]) }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        showAlertAction(title: "無法讀取位置", message: "請開啟定位服務", actions: [settingsAction, cancelAction])
        
        isDisplayingLocationServicesDenied = false
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    static var identifier: String {
        
        return String(describing: self)
    }
    
    var isHideNavigationBar: Bool {
        
        return false
    }
    
    var isEnableIQKeyboard: Bool {
        
        return true
    }
    
    override func viewDidLoad() {
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isHideNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        
        if !isEnableIQKeyboard {
            
            IQKeyboardManager.shared.enable = false
            
        } else {
            
            IQKeyboardManager.shared.enable = true
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if isHideNavigationBar {
            
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
        
        if !isEnableIQKeyboard {
            
            IQKeyboardManager.shared.enable = false
            
        } else {
            
            IQKeyboardManager.shared.enable = true
        }
        
    }
    
    @objc func popToPreviousPage(_ sender: UIButton) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func dismissVC() {
        
        dismiss(animated: true, completion: nil)
    }
    
    func showBlockAlertAction(uid: String) {
        
        let controller = UIAlertController(title: "封鎖用戶", message: "您將無法看見該用戶的訊息及揪團", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let blockAction = UIAlertAction(title: "封鎖", style: .destructive) { _ in
            
                        UserManager.shared.blockUser(blockUserId: uid)
            
                        UserManager.shared.userInfo.blockList?.append(uid)
        }
        
        controller.addAction(cancelAction)
        
        controller.addAction(blockAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func showAlertAction(
        title: String?,
        message: String? = "",
        preferredStyle: UIAlertController.Style = .alert,
        actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .cancel)] ) -> UIAlertController {
            
            let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
            
            for action in actions {
                controller.addAction(action)
            }
            
            self.present(controller, animated: true, completion: nil)
            
            // MARK: - iPad Present Code -
            
            controller.popoverPresentationController?.sourceView = self.view
            
            let xOrigin = self.view.bounds.width / 2
            
            let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)
            
            controller.popoverPresentationController?.sourceRect = popoverRect
            
            controller.popoverPresentationController?.permittedArrowDirections = .up
            
            return controller
        }
    
    // 前一頁的button
    func setNavigationBar(title: String) {
        
        self.title = "\(title)"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        let leftButton = PreviousPageButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        let image = UIImage(systemName: "chevron.left",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light ))
        // 改圖片
        leftButton.backgroundColor = .B5
        
        leftButton.tintColor = .B2
        
        leftButton.setImage(image, for: .normal) 
        
        leftButton.addTarget(self, action: #selector(popToPreviousPage), for: .touchUpInside)
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(customView: leftButton), animated: true)
    
    }
    
    @objc func showBikeViewController() {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "UBikeViewController") as? UBikeViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [.medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                LKProgressHUD.showFailure(text: "目前僅提供台北市Ubike")
            }}
    }
    
    @objc func presentRouteSelectionViewController() {
        
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "RouteSelectionViewController") as? RouteSelectionViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [ .medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                LKProgressHUD.showFailure(text: "網路問題，無法跳出")
            }
        }
    }
    
}
