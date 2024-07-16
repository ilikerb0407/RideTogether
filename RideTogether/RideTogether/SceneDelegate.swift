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

    func scene(_ scene: UIScene, _ session: UISceneSession, _ connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        if let currentUser = Auth.auth().currentUser {
            handleLoggedInUser(uid: currentUser.uid)
        } else {
            showLoginScreen()
        }

        window?.makeKeyAndVisible()
    }

    private func handleLoggedInUser(uid: String) {
        print("----------Current User ID: \(uid)----------")

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

        guard let tabbarVC = UIStoryboard.main.instantiateViewController(
            identifier: TabBarController.identifier) as? TabBarController else {
            print("Failed to instantiate TabBarController")
            return
        }

        window?.rootViewController = tabbarVC
        print("Fetch user info successfully")
    }

    private func handleFetchUserInfoError(_ error: Error) {
        print("Fetch user info failure: \(error)")
        showLoginScreen()
    }

    private func showLoginScreen() {
        guard let loginVC = UIStoryboard.login.instantiateViewController(
            identifier: LoginViewController.identifier) as? LoginViewController else {
            print("Failed to instantiate LoginViewController")
            return
        }

        window?.rootViewController = loginVC
    }
}
