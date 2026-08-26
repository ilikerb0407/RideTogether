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
