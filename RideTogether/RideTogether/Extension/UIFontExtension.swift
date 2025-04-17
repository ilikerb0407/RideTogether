//
//  UIFontExtension.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

enum FontName: String {
    case regular = "NotoSansTC-Regular"

    case bold = "NotoSansTC-Bold"

    case thin = "NotoSansTC-Thin"

    case light = "NotoSansTC-Light"

    case medium = "NotoSansTC-Medium"

    case black = "NotoSansTC-Black"
}

extension UIFont {
    static func regular(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.regular.rawValue, size: size)
    }

    static func bold(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.bold.rawValue, size: size)
    }

    static func thin(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.thin.rawValue, size: size)
    }

    static func light(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.light.rawValue, size: size)
    }

    static func medium(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.medium.rawValue, size: size)
    }

    static func black(size: CGFloat) -> UIFont? {
        UIFont(name: FontName.black.rawValue, size: size)
    }

    static func font(_ font: FontName, size: CGFloat) -> UIFont? {
        UIFont(name: font.rawValue, size: size)
    }
}
