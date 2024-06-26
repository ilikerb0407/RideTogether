//
//  AppDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift
import CoreData
import FirebaseAuth

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("didFinishLaunchingWithOptions")
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
        
        if let userId = Auth.auth().currentUser {
            
            print("\(userId.uid) and \(String(describing: userId.email))")
            
        }
        
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.B5 as Any]
        
        return true
        
    }
}
