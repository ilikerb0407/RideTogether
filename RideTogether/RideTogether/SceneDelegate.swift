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
        window?.rootViewController = TabBarController()
    }

    private func handleFetchUserInfoError(_ error: Error) {
        showLoginScreen()
        LKProgressHUD.showFailure(text: error.localizedDescription)
    }

    private func showLoginScreen() {
        window?.rootViewController = LoginViewController()
    }

}
