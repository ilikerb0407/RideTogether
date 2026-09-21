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

    static let journey = "Journey"

    static let profile = "Profile"

    static let main = "Main"
}

extension UIStoryboard {
    static var home: UIStoryboard { return storyboard(name: StoryboardCategory.home) }

    static var group: UIStoryboard { return storyboard(name: StoryboardCategory.group) }

    static var journey: UIStoryboard { return storyboard(name: StoryboardCategory.journey) }

    static var profile: UIStoryboard { return storyboard(name: StoryboardCategory.profile) }

    static var main: UIStoryboard { return storyboard(name: StoryboardCategory.main) }

    private static func storyboard(name: String) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: nil)
    }
}
