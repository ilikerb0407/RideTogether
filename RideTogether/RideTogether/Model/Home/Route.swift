//
//  Route.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import Foundation

struct Route: Codable, Hashable {
    
    let routeId: String
    let routeName: String
    let routeLevel: Int
    let routeLength: Double
    let routeInfo: String
    let routeMap: String
    // URL(String: record.reference)
    
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case routeName = "route_name"
        case routeLevel = "route_level"
        case routeLength = "route_length"
        case routeInfo = "route_info"
        case routeMap = "route_map"
    }
}
