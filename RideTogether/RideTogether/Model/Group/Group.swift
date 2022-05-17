//
//  Group.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/20.
//

import Foundation
import FirebaseFirestore
// + Hashable

struct Group: Codable {
    
    var groupId: String
    var groupName: String
    var hostId: String
    var date: Timestamp
    var limit: Int
    var routeName: String
    var note: String
    
    var userIds: [String]
    var isExpired: Bool?
    
    enum CodingKeys: String, CodingKey {
        
        case groupId = "group_id"
        case groupName = "group_name"
        case hostId = "host_id"
        case date
        case limit
        case routeName = "route_name"
        case note
        
        case userIds = "user_ids"
        case isExpired = "is_expired"
        
    }
    
    init() {
        self.groupId = ""
        self.groupName = ""
        self.hostId = ""
        self.date = Timestamp()
        self.limit = 0
        self.routeName = ""
        self.note = ""
        self.userIds = []
        self.isExpired = false
    }
        
}

