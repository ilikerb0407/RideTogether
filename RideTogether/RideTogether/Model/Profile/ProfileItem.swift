//
//  ProfileItem.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import Foundation
import UIKit


protocol ProfileItemContent {

    var title: String { get }
    
    var backgroundColor: UIColor? { get }
    
    var image: UIImage? { get }

}

enum ProfileItemType : ProfileItemContent, CaseIterable {
    
    case routeRecord
//    case recommendMap
    
    var title: String {
        switch self {
        case .routeRecord:
            return " My_Record "
//        case .recommendMap:
//            return "Recommend_Map"
        }
        
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .routeRecord:
            return UIColor.orange
//        case .recommendMap:
//            return UIColor.blue
        }
    }
    
    var image: UIImage? {
        switch self {
        case .routeRecord:
            return UIImage.init(named: "bike", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
//        case .recommendMap:
//            return UIImage.init(systemName: "map")
        }
    }
}
