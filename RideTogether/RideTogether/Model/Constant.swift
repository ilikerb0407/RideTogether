//
//  Constant.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation

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
    
    case savemaps = "toSavemaps"
    
}

enum Collection: String {
    
    case groups = "Groups"
    
    case messages = "Messages"
    
    case records = "Records"
  
    case routes = "Routes"

    case sharedmaps = "Sharemaps"
    
    case savemaps = "Savemaps"
    
    case requests = "Requests"
    
    case users = "Users"
    
    case maps = "Maps"
    
}
