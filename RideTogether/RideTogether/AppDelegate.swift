//
//  AppDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreData
import Firebase
import FirebaseAuth
import IQKeyboardManagerSwift
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
