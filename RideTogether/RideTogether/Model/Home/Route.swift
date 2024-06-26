//
//  Route.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import FirebaseFirestore
import Foundation

struct Route: Codable, Hashable {
    var uid: String?
    var createdTime: Timestamp
    var pictureRef: String?
    var routeId: String
    var routeName: String
    var routeTypes: Int
    var routeLength: String
    var routeInfo: String
    var routeMap: String

    enum CodingKeys: String, CodingKey {
        case uid // for UGC
        case createdTime = "created_time"
        case pictureRef = "picture_ref"
        case routeId = "route_id"
        case routeName = "route_name"
        case routeTypes = "route_types"
        case routeLength = "route_length"
        case routeInfo = "route_info"
        case routeMap = "route_map"
    }

    init() {
        self.uid = ""
        self.createdTime = Timestamp()
        self.pictureRef = ""
        self.routeId = ""
        self.routeName = ""
        self.routeTypes = 0
        self.routeLength = ""
        self.routeInfo = ""
        self.routeMap = ""
    }
}
