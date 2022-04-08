//
//  GPXRoot+length.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import MapKit
import CoreGPX

extension GPXRoot {
    
    public var tracksLength: CLLocationDistance {
        
        var tLength: CLLocationDistance = 0.0
        
        for track in self.tracks {
            
            tLength += track.length
        }
        
        return tLength
    }
}
