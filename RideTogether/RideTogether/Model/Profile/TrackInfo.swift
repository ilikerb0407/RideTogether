//
//  TrackInfo.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/16.
//

import Foundation


struct TrackInfo: Codable {
    
    var distance: Double
    var spentTime: TimeInterval
    var avgSpeed: Double
    var elevationDiff: Double
    var totalClimb: Double
    var totalDrop: Double
    
    init() {
        self.distance = 0.0
        self.spentTime = 0.0
        self.avgSpeed = 0.0
        self.elevationDiff = 0.0
        self.totalClimb = 0.0
        self.totalDrop = 0.0
    }
    
}

// ChartView

struct TrackChartData {
    
    var elevation: [Double] = []
    var time: [Double] = []
    var distance: [Double] = []
    
}
