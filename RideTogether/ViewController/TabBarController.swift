//
//  TabBarController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit

private enum Tabs {
    case home

    case group

    case journey

    case profile

    func controller() -> UIViewController {
        switch self {
        case .home:
            return UINavigationController(rootViewController: HomeViewController())

        case .group:
            return UINavigationController(rootViewController: GroupViewController())

        case .journey:
            return JourneyViewController()

        case .profile:
            return UINavigationController(rootViewController: ProfileViewController())
        }
    }
}

internal class TabBarController: UITabBarController, UITabBarControllerDelegate {
    static var identifier: String {
        String(describing: self)
    }

    private let customTabs: [Tabs] = [.journey, .home, .group, .profile]

    private var userInfo: UserInfo { UserManager.shared.userInfo }

    override func viewDidLoad() {
        super.viewDidLoad()

        let controllers = customTabs.map { $0.controller() }
        
        // 确保所有视图控制器都有正确的 tabBarItem 设置
        for (index, controller) in controllers.enumerated() {
            let tab = customTabs[index]
            configureTabBarItem(for: controller, tab: tab)
        }
        
        viewControllers = controllers

        addRequestListener()

        self.delegate = self

        self.tabBar.layer.masksToBounds = true

        self.tabBar.isTranslucent = true

        self.tabBar.layer.cornerRadius = 10

        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.B5]

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white

            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func configureTabBarItem(for controller: UIViewController, tab: Tabs) {
        // 获取实际的视图控制器（可能是 NavigationController 的 rootViewController）
        let actualVC: UIViewController
        if let navController = controller as? UINavigationController {
            actualVC = navController.topViewController ?? navController
        } else {
            actualVC = controller
        }
        
        switch tab {
        case .home:
            actualVC.tabBarItem = UITabBarItem(
                title: "探索",
                image: UIImage(systemName: "magnifyingglass.circle"),
                selectedImage: UIImage(systemName: "magnifyingglass.circle.fill")
            )
        case .group:
            actualVC.tabBarItem = UITabBarItem(
                title: "群組",
                image: UIImage(systemName: "rectangle.3.group.bubble.left"),
                selectedImage: UIImage(systemName: "rectangle.3.group.bubble.left.fill")
            )
        case .journey:
            actualVC.tabBarItem = UITabBarItem(
                title: "地圖",
                image: UIImage(systemName: "map"),
                selectedImage: UIImage(systemName: "map.fill")
            )
        case .profile:
            actualVC.tabBarItem = UITabBarItem(
                title: "個人",
                image: UIImage(systemName: "person.crop.circle"),
                selectedImage: UIImage(systemName: "person.crop.circle.fill")
            )
        }
    }

    private lazy var requests = [Request]()

    func addRequestListener() {
        GroupManager.shared.addRequestListener { result in

            switch result {
            case let .success(requests):

                var filtedRequests = [Request]()

                for request in requests where self.userInfo.blockList?.contains(request.requestId) == false {
                    filtedRequests.append(request)
                }

                self.requests = filtedRequests

                self.tabBar.items?[2].badgeValue = "\(self.requests.count)"

                self.tabBar.items?[2].badgeColor = .red

            case let .failure(error):

                LKProgressHUD.show(.failure("\(error)"))
            }
        }
    }
}
