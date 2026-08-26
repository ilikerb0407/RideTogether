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
        distance = 0.0
        spentTime = 0.0
        avgSpeed = 0.0
        elevationDiff = 0.0
        totalClimb = 0.0
        totalDrop = 0.0
    }
}

// ChartView

struct TrackChartData {
    var elevation: [Double] = []
    var time: [Double] = []
    var distance: [Double] = []
}
