//
//  Constant.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import SwiftUI

enum SegueIdentifier: String {

    case trailList = "toTrailList"

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
    
    case groups = "Groups"
    
    case messages = "Messages"
    
    case records = "Records"
    
    case requests = "Requests"
    
    case users = "Users"
    
    case trails = "Trails"
    
    //trails-maps
    
    case maps = "Maps"
    
}
