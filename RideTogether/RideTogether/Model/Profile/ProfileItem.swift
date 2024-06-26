//
//  ProfileItem.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import Charts
import Foundation
import UIKit

protocol ProfileItemContent {
    var title: String { get }

    var backgroundColor: UIColor? { get }

    var image: UIImage? { get }
}

enum ProfileItemType: ProfileItemContent, CaseIterable {
    case routeRecord

    case recommendMap

    case userAccount

    case saveRoutes

    var title: String {
        switch self {
        case .routeRecord:
            return "騎乘紀錄"
        case .recommendMap:
            return "分享牆"
        case .userAccount:
            return "帳戶設定"
        case .saveRoutes:
            return "收藏路線"
        }
    }

    var backgroundColor: UIColor? { .B5 }

    var image: UIImage? {
        switch self {
        case .routeRecord:
            return UIImage(systemName: "bicycle.circle")
        case .recommendMap:
            return UIImage(systemName: "map")
        case .userAccount:
            return UIImage(systemName: "person.circle")
        case .saveRoutes:
            return UIImage(systemName: "heart")
        }
    }
}
