//
//  UIColor+Extension.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit

private enum CSColor: String {
    
    // swiftlint:disable identifier_name
    case U1, U2, U3, U4
    case B1, B2, B3, B4, B5, B6
    case C1, C2, C3, C4
}

extension UIColor {

    static let U1 = CSColor(.U1)
    
    static let U2 = CSColor(.U2)
    
    static let U3 = CSColor(.U3)
    
    static let U4 = CSColor(.U4)
    
    static let B1 = CSColor(.B1)
    
    static let B2 = CSColor(.B2)
    
    static let B3 = CSColor(.B3)
    
    static let B4 = CSColor(.B4)
    
    static let B5 = CSColor(.B5)
    
    static let B6 = CSColor(.B6)
    
    static let C1 = CSColor(.C1)
    
    static let C2 = CSColor(.C2)
    
    static let C3 = CSColor(.C3)
    
    static let C4 = CSColor(.C4)
    
    // swiftlint:enable identifier_name
    
    private static func CSColor(_ color: CSColor) -> UIColor? {

        return UIColor(named: color.rawValue)
    }

    static func hexStringToUIColor(hex: String) -> UIColor {

        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
