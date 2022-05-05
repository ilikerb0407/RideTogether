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
    
    private let tabs: [Tab] = [ .journey, .group , .home , .profile]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControllers = tabs.map { $0.controller() }
        
        self.delegate = self
        
        self.tabBar.layer.masksToBounds = true
        
        self.tabBar.isTranslucent = true
        
        self.tabBar.layer.cornerRadius = 10
        
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}

