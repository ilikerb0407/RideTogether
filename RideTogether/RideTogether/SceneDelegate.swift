//
//  SceneDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import FirebaseAuth
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {

        if Auth.auth().currentUser != nil {
            if let uid = Auth.auth().currentUser?.uid {
                print("----------Current User ID: \(uid)----------")

                UserManager.shared.fetchUserInfo(uid: uid) { result in

                    switch result {
                    case let .success(userInfo):

                        UserManager.shared.userInfo = userInfo

                        guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                            identifier: TabBarController.identifier) as? TabBarController else {
                            return
                        }

                        self.window?.rootViewController = tabbarVC

                        print("Fetch user info successfully")

                    case let .failure(error):

                        print("Fetch user info failure: \(error)")
                    }
                }
            }

        } else {
            guard let loginVC = UIStoryboard.login.instantiateViewController(
                identifier: LoginViewController.identifier) as? LoginViewController else {
                return
            }

            self.window?.rootViewController = loginVC
        }
    }
}
