//
//  GPXRoot+length.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation
import MapKit

public extension GPXRoot {
    var tracksLength: CLLocationDistance {
        var tLength: CLLocationDistance = 0.0

        for track in tracks {
            tLength += track.length
        }

        return tLength
    }
}
