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


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
//    swiftlint:disable force_cast
//    static let shared = UIApplication.shared.delegate as! AppDelegate
//    // swiftlint:enable force_cast
//    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//    Override point for customization after application launch.
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
//        Thread.sleep(forTimeInterval: 3)
        
        if let userId = Auth.auth().currentUser {
            
            print ("\(userId.uid) and \(userId.email)")
            
        }
        return true
        
//     Navigatiob Bar Item Color
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor :  UIColor.B5]

//      Tab Bar color
//                UITabBar.appearance().tintColor = UIColor.B5
        
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: screen rotation
    
    var shouldAutorotate = false
    
    func application(_ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?) ->
    UIInterfaceOrientationMask {
//        if shouldAutorotate {
//            return .allButUpsideDown
//        } else {
//            return .portrait
//        }
        let deviceOrientation = UIInterfaceOrientationMask.portrait
        return deviceOrientation
        
    }
    /// Default placeholder function
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "OpenGpxTracker", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
        }()
    
    /// Default placeholder function
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and
        // return a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("open-gpx-tracker-session.sqlite")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url,
                                               options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                                         NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    /// Default placeholder function
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application
        // (which is already bound to the persistent store coordinator for the application.)
        // This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
}

/// Notifications for file receival from external source.
extension Notification.Name {
    
    /// Use when a file is received from external source.
    static let didReceiveFileFromURL = Notification.Name("didReceiveFileFromURL")
    
    /// Use when a file is received from Apple Watch.
//    static let didReceiveFileFromAppleWatch = Notification.Name("didReceiveFileFromAppleWatch")
}
