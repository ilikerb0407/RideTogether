//
//  RouteCategory.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//
//  Renamed from `RoutesType.swift` / `enum RoutesType`. Also dropped
//  `import SwiftUI` — this file is pure UIKit (returns UIImage, not
//  SwiftUI's Image), the import was unused.

import Foundation
import UIKit

// TODO: 這個功能是 copy 別人的想法的ＸＤ，我之後會想要思考怎麼優化這個功能的的 business logic
enum RouteCategory: String, CaseIterable {
    case userOne = "朋友路線"

    case recommendOne = "推薦路線"

    case riverOne = "河堤路線"

    case mountainOne = "爬山路線"

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
}
