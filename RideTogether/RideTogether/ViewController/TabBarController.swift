//
//  TabBarController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import Firebase
import UIKit

private enum Tab {
    case home

    case group

    case journey

    case profile

    func controller() -> UIViewController {
        switch self {
        case .home:
            // Was `UIStoryboard.home.instantiateInitialViewController()!`,
            // which resolved Home.storyboard's UINavigationController
            // scene (wrapping HomeViewController, with its tabBarItem set
            // in Interface Builder to title "探索" + the
            // magnifyingglass.circle system image). Built directly now
            // that HomeViewController no longer needs to be loaded from a
            // Storyboard; the tabBarItem is set explicitly below since
            // nothing else supplies it anymore.
            let navigationController = UINavigationController(rootViewController: HomeViewController())
            navigationController.tabBarItem = UITabBarItem(
                title: "探索",
                image: UIImage(systemName: "magnifyingglass.circle"),
                tag: 0
            )
            return navigationController

        case .group: return UIStoryboard.group.instantiateInitialViewController()!

        case .journey: return UIStoryboard.journey.instantiateInitialViewController()!

        case .profile: return UIStoryboard.profile.instantiateInitialViewController()!
        }
    }
}

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    static var identifier: String {
        return String(describing: self)
    }

    private let appTabs: [Tab] = [.journey, .home, .group, .profile]

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = appTabs.map { $0.controller() }

        addRequestListener()

        delegate = self

        tabBar.layer.masksToBounds = true

        tabBar.isTranslucent = true

        tabBar.layer.cornerRadius = 10

        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = UIColor.B5
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.B5]

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
    private var requestListenerRegistration: ListenerRegistration?

    deinit {
        requestListenerRegistration?.remove()
    }

    func addRequestListener() {
        requestListenerRegistration = GroupManager.shared.addRequestListener { [weak self] result in

            guard let self = self else { return }

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

                print("fetchData.failure: \(error)")
            }
        }
    }
}
