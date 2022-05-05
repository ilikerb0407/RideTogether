//
//  ProfileItem.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import Foundation
import UIKit
import Charts

// 個人Pofile 頁面的TableViewCell 呈現資料

protocol ProfileItemContent {

    var title: String { get }
    
    var backgroundColor: UIColor? { get }
    
    var image: UIImage? { get }

}

enum ProfileItemType : ProfileItemContent, CaseIterable {
    
    case routeRecord
    
    case recommendMap
    
    case userAccount
    
    case saveRoutes
    
    case privacy
    
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
        case .privacy :
            return "隱私權設定"
        }
        
    }
    
    var backgroundColor: UIColor? {
        
        switch self {
        case .routeRecord:
            return .B5
        case .recommendMap:
            return .B5
        case .userAccount:
            return .B5
        case .saveRoutes:
            return .B5
        case .privacy:
            return .B5
        }
    }
    
    var image: UIImage? {
        switch self {
        case .routeRecord:
            return UIImage.init(systemName: "bicycle.circle")
        case .recommendMap:
            return UIImage.init(systemName: "map")
        case .userAccount:
            return UIImage.init(systemName: "person.circle")
        case .saveRoutes:
            return UIImage.init(systemName: "heart")
        case .privacy:
            return UIImage.init(systemName: "")
        }
    }
}
