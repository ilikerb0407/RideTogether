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
            return HomeViewController()

        case .group:
            return GroupViewController()

        case .journey:
            // 从 Storyboard 加载以确保 outlet 正确连接
            if let journeyVC = UIStoryboard.journey.instantiateViewController(
                withIdentifier: "JourneyViewController") as? JourneyViewController {
                return journeyVC
            }
            // 如果 Storyboard 加载失败，返回代码创建的实例（但 mapView 会是 nil）
            return JourneyViewController()

        case .profile:
            return ProfileViewController()
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

        viewControllers = customTabs.map { $0.controller() }

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
