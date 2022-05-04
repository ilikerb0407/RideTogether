//
//  RecommendDetailViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import UIKit
import SwiftUI
import MapKit
import Firebase
import CoreGPX
import CoreLocation

// MARK: RecommendRoute
//MARK: No Use!!!


class RecommendDetailViewController: UIViewController {
    
    
    @IBOutlet weak var map2: GPXMapView!
    
    private let mapViewDelegate = MapViewDelegate()
    
    // 只會有一筆
    var record = Record()
    
    lazy var trackInfo = TrackInfo()
    
    lazy var trackChartData = TrackChartData()
    
    func setUp() {
        
        navigationController?.isNavigationBarHidden = true
        
        map2.delegate = mapViewDelegate
        
        self.view.addSubview(map2)
        
        tabBarController?.tabBar.isHidden = true
        
        backButton()
        
        praseGPXFile()
        
        backToJourneyButton()
        
//        updateInfo(data: trackInfo)
//
//        setChart(xValues: trackChartData.distance, yValues: trackChartData.elevation)
    }
    
//    func updateInfo(data: TrackInfo) {
//
//        totalTime.text = data.spentTime.tohmsTimeFormat()
//
//        totalDistance.text = data.distance.toDistance()
//
//        let speed = data.distance / data.spentTime
//
//        avgSpeed.text = speed.toSpeed()
//
//    }
    
    
//    func setChart(xValues: [Double], yValues: [Double]) {
//
//        var dataEntries: [ChartDataEntry] = []
//
//        //        chartView.noDataText = "Can not get track record!"
//
//        for index in 0..<trackChartData.elevation.count {
//
//            let xvalue = xValues[index] / 1000 // m -> km
//
//            let yvalue = yValues[index]
//
//            let dataEntry = ChartDataEntry(x: xvalue, y: yvalue)
//
//            dataEntries.append(dataEntry)
//        }
//
//        let dataSet = LineChartDataSet(entries: dataEntries, label: "")
//
//        dataSet.colors = [.U1 ?? .systemGray]
//        dataSet.drawFilledEnabled = true
//        dataSet.drawCirclesEnabled = false
//        dataSet.drawValuesEnabled = false
//        dataSet.lineWidth = 2
//        dataSet.fillAlpha = 0.8
//        dataSet.fillColor = .U2 ?? .lightGray
//
//        chartView.data = LineChartData(dataSets: [dataSet])
//
//        chartView.xAxis.setLabelCount(yValues.count, force: true)
//
//        chartView.legend.enabled = false
//
//        setUpChartLayout()
//    }
    
//    func setUpChartLayout() {
//
//        let xAxis = chartView.xAxis
//        xAxis.labelPosition = .bottom
//        xAxis.setLabelCount(10, force: false)
//        xAxis.drawGridLinesEnabled = true
//        xAxis.granularityEnabled = true
//
//        let yAxis = chartView.leftAxis
//        yAxis.axisMinimum = 0
//        yAxis.setLabelCount(10, force: false)
//        yAxis.labelPosition = .outsideChart
//        yAxis.drawGridLinesEnabled = true
//        yAxis.granularityEnabled = true
//
//        chartView.rightAxis.enabled = false
//
//        chartView.animate(xAxisDuration: 2.0)
//    }
    
//
    func backToJourneyButton() {
        let button = NextPageButton(frame: CGRect(x: 270 , y: 50, width: 80, height: 80))
        button.addTarget(self, action: #selector(push), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func push(_ sender: UIButton) {

        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "FollowJourneyViewController") as? FollowJourneyViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.record = record
            // 這一頁宣告的變數, 是下一頁的變數 (可以改用closesure傳看看)
        }
        print ("push")
    }
    
    func backButton() {
        let button = PreviousPageButton(frame: CGRect(x: 20, y: 50, width: 40, height: 40))
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func popToPreviosPage(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func praseGPXFile() {
        
        if let inputUrl = URL(string: record.recordRef) {
            
            print("TrackDetail:\(inputUrl)")
            
            guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return }
            
            didLoadGPXFile(gpxRoot: gpx)
            processTrackInfo(gpxRoot: gpx)
            
        }
    }
    
    func processTrackInfo(gpxRoot: GPXRoot) {
        var temArray: [Double] = []
        
        for track in gpxRoot.tracks {
            
            var lastLength: Double = 0.0
            
            for segment in track.segments {
                
                for trackPoints in segment.points {
                    
                    if let ele = trackPoints.elevation,
                       
                        let time = trackPoints.time?.timeIntervalSinceReferenceDate {
                        trackChartData.elevation.append(ele)
                        trackChartData.time.append(Double(time))
                    }
                }
                // add the last segment endpoint to coordinate of the next segment
                let segmentLength = segment.distanceFromOrigin().map { $0 + lastLength }
                
                lastLength = segmentLength.last ?? 0
                
                temArray += segmentLength
            }
        }
        
        trackChartData.distance = temArray
        
        trackChartData.time = trackChartData.time.map { $0 - self.trackChartData.time[0]}
        
        trackInfo.distance = trackChartData.distance.last ?? 0
        
        trackInfo.spentTime = trackChartData.time.last ?? 0
        
        processDiffOfElevation(elevation: trackChartData.elevation)
    }
    
    func processDiffOfElevation(elevation: [Double]) {
        
        var totalClimp: Double = 0.0
        
        var totalDrop: Double = 0.0
        
        if elevation.count != 0 {
            
            for index in 0..<elevation.count - 1 {
                
                let diff = elevation[index + 1] - elevation[index]
                
                if diff < 0 && abs(diff) < 1.35 {
                    
                    totalDrop += diff
                    
                } else if diff > 0 && abs(diff) < 1.35 {
                    
                    totalClimp += diff
                }
            }
        }
        
        totalDrop = abs(totalDrop)
        
        trackInfo.totalClimb = totalClimp
        
        trackInfo.totalDrop = totalDrop
        
        if let maxValue = trackChartData.elevation.max(),
           let minValue = trackChartData.elevation.min() {
            
            trackInfo.elevationDiff = maxValue - minValue
        }
    }
    // load 不出線
    func didLoadGPXFile(gpxRoot: GPXRoot) {
        
        map2.importFromGPXRoot(gpxRoot)

        map2.regionToGPXExtent()
    }
    // MARK: - Polyline -
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    func updatePolylineColor() {
        
        for overlay in map2.overlays where overlay is MKPolyline {
            
            map2.removeOverlay(overlay)
            
            map2.addOverlay(overlay)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        
    }
    
    // 改成 instantiate storybroad 然後改寫成 closure 的方式把資料傳過去, 去看作業的 passValue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.recommendMaps.rawValue {
            if let nextVC = segue.destination as? FollowJourneyViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                    
                }
            }
        }
    }
}
