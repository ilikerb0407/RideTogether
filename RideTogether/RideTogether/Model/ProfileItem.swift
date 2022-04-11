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

}

enum ProfileItemType : ProfileItemContent, CaseIterable {
    
    case routeRecord
    
    var title: String {
        switch self {
        case .routeRecord:
            return " My_Record "
        }
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .routeRecord:
            return UIColor.orange
        }
    }
}
