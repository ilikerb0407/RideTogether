//
//  ProfileItem.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import Foundation
import UIKit

// 個人Pofile 頁面的TableViewCell 呈現資料

protocol ProfileItemContent {

    var title: String { get }
    
    var backgroundColor: UIColor? { get }
    
    var image: UIImage? { get }

}

enum ProfileItemType : ProfileItemContent, CaseIterable {
    
    case routeRecord
    case recommendMap
    
    var title: String {
        switch self {
        case .routeRecord:
            return "騎乘紀錄"
        case .recommendMap:
            return "分享牆"
        }
        
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .routeRecord:
            return UIColor.orange
        case .recommendMap:
            return UIColor.orange
        }
    }
    
    var image: UIImage? {
        switch self {
        case .routeRecord:
            return UIImage.init(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        case .recommendMap:
            return UIImage.init(systemName: "map")
        }
    }
}
