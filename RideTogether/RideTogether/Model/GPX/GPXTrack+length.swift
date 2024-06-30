//
//  GPXTrack+length.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation
import MapKit

extension GPXTrack {
    public var length: CLLocationDistance {
        var trackLength: CLLocationDistance = 0.0

        for segment in segments {
            trackLength += segment.length()
        }

        return trackLength
    }
}
