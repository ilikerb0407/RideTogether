//
//  Route.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import Foundation
import FirebaseFirestore

struct Route: Codable, Hashable {
    
    var routeId: String
    var routeName: String
    var routeTypes: Int
    var routeLength: String
    var routeInfo: String
    var routeMap: String
    // URL(String: record.reference)
    
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case routeName = "route_name"
        case routeTypes = "route_types"
        case routeLength = "route_length"
        case routeInfo = "route_info"
        case routeMap = "route_map"
    }
    
    init() {
        self.routeId = ""
        self.routeName = ""
        self.routeTypes = 0
        self.routeLength = ""
        self.routeInfo = ""
        self.routeMap = ""
        
    }
}
