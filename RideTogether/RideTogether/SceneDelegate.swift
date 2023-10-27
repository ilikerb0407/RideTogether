//
//  SceneDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = .init(windowScene: windowScene)

        // TODO: rootViewController
//        window?.rootViewController =

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) { }

    func sceneDidBecomeActive(_: UIScene) { }

    func sceneWillResignActive(_: UIScene) { }

    func sceneWillEnterForeground(_: UIScene) { }

    func sceneDidEnterBackground(_: UIScene) { }
}

