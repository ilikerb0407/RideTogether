//
//  RoutesType.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import Foundation
import UIKit

enum RoutesType: Int, CaseIterable {
    case userOne

    case recommendOne

    case riverOne

    case mountainOne
    
    var title: String {
        switch self {
        case .userOne:
            return "朋友路線"
        case .recommendOne:
            return "推薦路線"
        case .riverOne:
            return "河堤路線"
        case .mountainOne:
            return "爬山路線"
        }
    }

    var image: UIImage? {
        switch self {
        case .userOne:
            return UIImage(named: "type0")
        case .recommendOne:
            return UIImage(named: "type1")
        case .riverOne:
            return UIImage(named: "type2")
        case .mountainOne:
            return UIImage(named: "type3")
        }
    }
    
    static func from(value: Int) -> RoutesType? {
        return RoutesType.allCases.first(where: { $0.rawValue == value })
    }
}
