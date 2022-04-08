//
//  TimeFormater.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import FirebaseFirestore

enum TimeFormater: String {
    
    case dateStyle = "yyyy/MM/dd"
    
    case timeStyle = "HH:mm"
    
    case preciseTime = "yyyy/MM/dd  HH:mm"
    
    case preciseTimeForFilename = "yyyy-MM-dd_HH-mm"
    
    func timestampToString(time: Timestamp) -> String {
        
        let timeInterval = time
        
        let date = timeInterval.dateValue()
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = self.rawValue
        
        let formatTime = dateFormatter.string(from: date as Date)
        
        return formatTime
    }
    
    func dateToString(time: Date) -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = self.rawValue
        
        let formatTime = dateFormatter.string(from: time as Date)
        
        return formatTime
    }
}

extension Timestamp {
    
    func checkIsExpired() -> Bool {
        
        let localTime = Timestamp()
        
        return localTime.seconds > self.seconds ? true : false
    }
}
