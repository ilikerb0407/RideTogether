//
//  UIStorybroad.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/26.
//

import UIKit

private enum StoryboardCategory {

    static let profile = "Profile"

    static let main = "Main"
}

extension UIStoryboard {

    static var profile: UIStoryboard { return storyboard(name: StoryboardCategory.profile) }

    static var main: UIStoryboard { return storyboard(name: StoryboardCategory.main) }

    private static func storyboard(name: String) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: nil)
    }
}
