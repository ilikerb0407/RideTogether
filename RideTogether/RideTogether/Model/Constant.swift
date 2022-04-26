//
//  Constant.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import SwiftUI

enum SegueIdentifier: String {

    case route = "routeList"
    
    case routeList = "toRouteList"

    case trailInfo = "toTrailInfo"

    case requestList = "toRequestList"
    
    case groupChat = "toGroupChat"
    
    case buildTeam = "toBuildTeam"
    
    case userRecord = "toUserRecord"
    
    case recommendMaps = "toRecommendMaps"
}


enum ProfileSegue: String, CaseIterable {
    
    case record = "toRecord"

    case recommendMap = "toRecommend"
    
    case account = "toAccount"
    
    case privacy = "toPrivacy"
}

enum Collection: String {
    
    //MARK:  左邊是 storage 的文件名稱 右邊是 firebase database 的文件名稱
    
    case groups = "Groups"
    
    case messages = "Messages"
    
    case records = "Records"
    
    // Trails 是推薦路線
    
    case routes = "Routes"
    
    // 塗鴉牆
    case sharedmaps = "Sharemaps"
    
    case requests = "Requests"
    
    case users = "Users"
    
    // maps 是離線地圖
    
    case maps = "Maps"
    
}
