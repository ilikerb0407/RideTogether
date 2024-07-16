//
//  AppDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import Firebase
import FirebaseAuth
import IQKeyboardManagerSwift

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupFirebase()

        setupKeyboardManager()

        setupNavigationBarAppearance()

        logCurrentUser()

        return true
    }

    private func setupFirebase() {
        FirebaseApp.configure()
    }

    private func setupKeyboardManager() {
        IQKeyboardManager.shared.enable = true
    }

    private func setupNavigationBarAppearance() {
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.B5]
    }

    private func logCurrentUser() {
        if let currentUser = Auth.auth().currentUser {
            print("Current User UID: \(currentUser.uid)")
            print("Current User Email: \(currentUser.email ?? "N/A")")
        } else {
            print("No user currently logged in")
        }
    }
}
