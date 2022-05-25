//
//  TabBarController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit

private enum Tab {
    
    case home
    
    case group
    
    case journey
    
    case profile
    
    func controller() -> UIViewController {
        
        var controller: UIViewController
        
        switch self {
            
        case .home: controller = UIStoryboard.home.instantiateInitialViewController()!
            
        case .group: controller = UIStoryboard.group.instantiateInitialViewController()!
            
        case .journey: controller = UIStoryboard.journey.instantiateInitialViewController()!
            
        case .profile: controller = UIStoryboard.profile.instantiateInitialViewController()!
        
        }
        
        return controller
    }
}

class TabBarController: UITabBarController, UITabBarControllerDelegate {
  
    static var identifier: String {
        
        return String(describing: self)
    }
     
    private let tabs: [Tab] = [.journey, .home,.group, .profile]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControllers = tabs.map { $0.controller() }
        
        addRequestListener()
        
        self.delegate = self
        
        self.tabBar.layer.masksToBounds = true
        
        self.tabBar.isTranslucent = true
        
        self.tabBar.layer.cornerRadius = 10
        
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor:  UIColor.B5]
        
        if #available(iOS 15.0, *) {
                   let appearance = UITabBarAppearance()
                   appearance.configureWithOpaqueBackground()
//                 appearance.backgroundColor = UIColor.hexStringToUIColor(hex: "#A2BDC6")
                   appearance.backgroundColor = UIColor.white

                   self.tabBar.standardAppearance = appearance
                   self.tabBar.scrollEdgeAppearance = appearance
                }
         

    }
    
    private var userInfo: UserInfo { UserManager.shared.userInfo }
    private lazy var requests = [Request]()
    
    func addRequestListener() {
        
        GroupManager.shared.addRequestListener { result in
            
            switch result {
                
            case .success(let requests):
                
                var filtedRequests = [Request]()
                
                for request in requests where self.userInfo.blockList?.contains(request.requestId) == false {
                    
                    filtedRequests.append(request)
                }
                
                self.requests = filtedRequests
                
                self.tabBar.items?[2].badgeValue = "\(self.requests)"
                
                self.tabBar.items?[2].badgeColor = .red
                
            case .failure(let error):
                
                print("fetchData.failure: \(error)")
            }
        }
    }
    
    
}
extension Notification.Name {
    static let didUpdateBuyItemList = Notification.Name("didUpdateBuyItemList")
}

