//
//  ProfileItem.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import Foundation
import UIKit
import Charts


enum ProfileItemType:  CaseIterable {
    
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
        }
        
    }
}
