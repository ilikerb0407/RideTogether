//
//  SceneDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import FirebaseAuth

internal class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    override init() {
        super.init()
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user == nil {
                self?.showLoginScreen()
            }
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        configureWindow(for: windowScene)
    }
}

extension SceneDelegate {
    private func configureWindow(for windowScene: UIWindowScene) {
        window = UIWindow(windowScene: windowScene)
        guard let currentUser = Auth.auth().currentUser else {
            showLoginScreen()
            return
        }
        
        handleLoggedInUser(uid: currentUser.uid)
        window?.makeKeyAndVisible()
    }

    private func handleLoggedInUser(uid: String) {

        UserManager.shared.fetchUserInfo(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    self?.setupTabBarController(with: userInfo)
                case .failure(let error):
                    self?.handleFetchUserInfoError(error)
                }
            }
        }
    }

    private func setupTabBarController(with userInfo: UserInfo) {
        UserManager.shared.userInfo = userInfo

        guard let tabbarVC = UIStoryboard(name: Constants.Storyboard.main, bundle: nil)
                .instantiateViewController(identifier: Constants.ViewControllerID.tabBarController) as? TabBarController else {
            presentErrorAlert(with: "Failed to instantiate TabBarController")
            return
        }

        window?.rootViewController = tabbarVC
    }
    
    private func handleFetchUserInfoError(_ error: Error) {
        showLoginScreen()
        presentErrorAlert(with: error.localizedDescription)
    }

    private func showLoginScreen() {
        if let loginVC = UIStoryboard(name: Constants.Storyboard.login, bundle: nil)
                .instantiateViewController(identifier: Constants.ViewControllerID.loginViewController) as? LoginViewController {
            window?.rootViewController = loginVC
        } else {
            presentErrorAlert(with: "Failed to instantiate LoginViewController")
        }
    }

    private func presentErrorAlert(with message: String) {
        guard let rootVC = window?.rootViewController else { return }
        let alert = UIAlertController(title: Constants.Alert.errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.Alert.okActionTitle, style: .default, handler: nil))
        rootVC.present(alert, animated: true)
    }
}
