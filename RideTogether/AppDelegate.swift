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

internal class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupInitialConfigurations()
        return true
    }

    private func setupInitialConfigurations() {
        setupFirebase()
        setupKeyboardManager()
    }

    private func setupFirebase() {
        FirebaseApp.configure()
    }

    private func setupKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
    }
}
