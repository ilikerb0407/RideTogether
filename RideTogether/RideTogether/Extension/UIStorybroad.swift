//
//  UIStorybroad.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit

private enum StoryboardCategory {
    static let home = "Home"

    static let group = "Group"

    static let login = "Login"

    static let journey = "Journey"

    static let profile = "Profile"

    static let policy = "Policy"

    static let main = "Main"
}

extension UIStoryboard {
    static var home: UIStoryboard { storyboard(name: StoryboardCategory.home) }

    static var group: UIStoryboard { storyboard(name: StoryboardCategory.group) }

    static var login: UIStoryboard { storyboard(name: StoryboardCategory.login) }

    static var journey: UIStoryboard { storyboard(name: StoryboardCategory.journey) }

    static var profile: UIStoryboard { storyboard(name: StoryboardCategory.profile) }

    static var policy: UIStoryboard { storyboard(name: StoryboardCategory.policy) }

    static var main: UIStoryboard { storyboard(name: StoryboardCategory.main) }

    private static func storyboard(name: String) -> UIStoryboard {
        UIStoryboard(name: name, bundle: nil)
    }
}
