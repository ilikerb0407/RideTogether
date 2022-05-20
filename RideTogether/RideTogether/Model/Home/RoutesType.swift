//
//  RoutesType.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import Foundation

import UIKit
import SwiftUI


protocol RoutesPhoto {
    
    var image : UIImage? { get }
    
}

enum RoutesType: String, RoutesPhoto, CaseIterable {
    
    case userOne = "朋友路線"
    
    case recommendOne = "推薦路線"
    
    case riverOne = "河堤路線"
    
    case mountainOne = "爬山路線"
   
    var image: UIImage? {
        
        switch self {
            // 394 * 204 圖片好的畫質 上傳前注意
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
