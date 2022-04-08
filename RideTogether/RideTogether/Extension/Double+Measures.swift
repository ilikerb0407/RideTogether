//
//  Double+Measures.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation

let metersPerKilometer = 1000.0

let kilometersPerHourInOneMeterPerSecond = 3.6

extension Double {
    
    func toKilometers() -> Double {
        return self/metersPerKilometer
    }
    
    func toKilometers() -> String {
        return String(format: "%.1fkm", toKilometers() as Double)
    }
    
    func toMeters() -> String {
        return String(format: "%.0fm", self)
    }
    
    func toDistance() -> String {
        return self > metersPerKilometer ? toKilometers() as String : toMeters() as String
    }
    
    func toKilometersPerHour() -> Double {
        return self * kilometersPerHourInOneMeterPerSecond
    }
    
    func toKilometersPerHour() -> String {
        return String(format: "%.1fkm/h", toKilometersPerHour() as Double)
    }
    
    func toSpeed() -> String {
        return toKilometersPerHour() as String
    }
    
    func toAltitude() -> String {
        return String(format: "%.1fm", self)
    }
    
    func toAccuracy(useImperial: Bool = false) -> String {
        return "±\(toMeters() as String)"
    }
    
    func tohmsTimeFormat () -> String {
        
        let seconds = Int(self)
        
        let hour = seconds / 3600
        
        let minute = (seconds % 3600) / 60
        
        let second = (seconds % 3600) % 60
        
        var timeString = ""
        
        timeString += hour.description
        
        timeString += ":"
        
        timeString += minute.description
        
        timeString += ":"
        
        timeString += second.description
        
        return timeString
    }
}

extension String {

    func removeFileSuffix() -> String {
        
        var components = self.components(separatedBy: ".")
        
        if components.count > 1 {
            
          components.removeLast()
            
          return components.joined(separator: ".")
            
        } else {
            
          return self
        }
    }
}
