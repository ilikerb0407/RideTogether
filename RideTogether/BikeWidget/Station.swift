//
//  Station.swift
//  RideTogether
//
//  Created by 00591630 on 2022/11/3.
//

import SwiftUI
import CoreLocation
import MapKit

struct Station: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let bikeCapacity: Int
    let distance: Double
    let coordinates: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case id = "station_id"
        case name
        case address
        case bikeCapacity = "capacity"
        case distance = "nearby_distance"
        case latitude = "lat"
        case longitude = "lon"
    }

    init(id: String,
         name: String,
         address: String,
         bikeCapacity: Int,
         distance: Double,
         coordinates: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.address = address
        self.bikeCapacity = bikeCapacity
        self.distance = distance
        self.coordinates = coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        bikeCapacity = try container.decode(Int.self, forKey: .bikeCapacity)
        distance = try container.decode(Double.self, forKey: .distance)

        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
        
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encode(address, forKey: .address)
      try container.encode(bikeCapacity, forKey: .bikeCapacity)
      try container.encode(distance, forKey: .distance)
      try container.encode(coordinates.latitude, forKey: .latitude)
      try container.encode(coordinates.longitude, forKey: .longitude)
    }
    
}
