//
//  SceneDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        print("willConnectTo")
        
        if Auth.auth().currentUser != nil {
            
            if let uid = Auth.auth().currentUser?.uid {
                
                print("----------Current User ID: \(uid)----------")
                
                UserManager.shared.fetchUserInfo(uid: uid) { result in
                    
                    switch result {
                        
                    case .success(let userInfo):
                        
                        UserManager.shared.userInfo = userInfo
                        
                        guard let tabbarVC = UIStoryboard.main.instantiateViewController(
                            
                            identifier: TabBarController.identifier) as? TabBarController else { return }
                        
                        self.window?.rootViewController = tabbarVC
                        
                        print("Fetch user info successfully")
                        
                    case .failure(let error):
                        
                        print("Fetch user info failure: \(error)")
                    }
                }
            }
            
        } else {
            
            guard let loginVC = UIStoryboard.login.instantiateViewController(
                
                identifier: LoginViewController.identifier) as? LoginViewController else { return }
            
            self.window?.rootViewController = loginVC
        }
        
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        
        print("sceneDidDisconnect")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("sceneDidBecomeActive")
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("sceneWillResignActive")
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("sceneWillEnterForeground")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("sceneDidEnterBackground")
    }
    
}
