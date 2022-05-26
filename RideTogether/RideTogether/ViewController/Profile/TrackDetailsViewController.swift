//
//  TrackDetailsViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/11.
//

import UIKit
import SwiftUI
import MapKit
import Firebase
import CoreGPX
import CoreLocation
import Charts

//MARK: User Record detail

class TrackDetailsViewController: BaseViewController, ChartViewDelegate {
    
    @IBOutlet weak var map: GPXMapView!
    
    // MARK: recordInfoView
    
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var totalDistance: UILabel!
    @IBOutlet weak var avgSpeed: UILabel!
    
    
    @IBOutlet weak var chartView: LineChartView! {
        didSet {
            chartView.delegate = self
        }
    }
    
    
    @IBOutlet weak var gView: UIView! {
        
        didSet {
            gView.applyGradient(
                colors: [.white, .B3],
                locations: [0.0, 1.0], direction: .leftSkewed)
            gView.alpha = 0.5
        }
    }
    
    private let mapViewDelegate = MapPin()
    
    // 只會有一筆
    var record = Record()
    
    lazy var trackInfo = TrackInfo()
    
    lazy var trackChartData = TrackChartData()
    
    func setUp() {
        
        //        navigationController?.isNavigationBarHidden = false
        
        setNavigationBar(title: "騎乘紀錄")
        
        map.delegate = mapViewDelegate
        
        self.view.addSubview(map)
        
        tabBarController?.tabBar.isHidden = true
        
        //        backButton()
        
        praseGPXFile()
        
//        backToJourneyButton()
        
        updateInfo(data: trackInfo)
        
        setChart(xValues: trackChartData.distance, yValues: trackChartData.elevation)
    }
    
    func updateInfo(data: TrackInfo) {
        
        totalTime.text = data.spentTime.tohmsTimeFormat()
        
        totalDistance.text = data.distance.toDistance()
        
        let speed = data.distance / data.spentTime
        
        avgSpeed.text = speed.toSpeed()
        
    }
    
    
    func setChart(xValues: [Double], yValues: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        //        chartView.noDataText = "Can not get track record!"
        
        for index in 0..<trackChartData.elevation.count {
            
            let xvalue = xValues[index] / 1000 // m -> km
            
            let yvalue = yValues[index]
            
            let dataEntry = ChartDataEntry(x: xvalue, y: yvalue)
            
            dataEntries.append(dataEntry)
        }
        
        let dataSet = LineChartDataSet(entries: dataEntries, label: "")
        
        dataSet.colors = [.C1 ?? .systemGray]
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2
        dataSet.fillAlpha = 0.8
        dataSet.fillColor = .U2 ?? .lightGray
        
        chartView.data = LineChartData(dataSets: [dataSet])
        
        chartView.xAxis.setLabelCount(yValues.count, force: true)
        
        chartView.legend.enabled = false
        
        setUpChartLayout()
    }
    
    func setUpChartLayout() {
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.setLabelCount(10, force: false)
        xAxis.drawGridLinesEnabled = true
        xAxis.granularityEnabled = true
        
        let yAxis = chartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.setLabelCount(10, force: false)
        yAxis.labelPosition = .outsideChart
        yAxis.drawGridLinesEnabled = true
        yAxis.granularityEnabled = true
        
        chartView.rightAxis.enabled = false
        
        chartView.animate(xAxisDuration: 2.0)
    }
    
    func backToJourneyButton() {
        
        let button = NextPageButton(frame: CGRect(x: UIScreen.width - 60 , y: 460 , width: 50, height: 50))
        button.addTarget(self, action: #selector(push), for: .touchUpInside)
        view.addSubview(button)
        
    }
    
    @objc func push(_ sender: UIButton) {
         
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "RideViewController") as? RideViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.record = record
            // 這一頁宣告的變數, 是下一頁的變數 (可以改用closesure傳看看)
        }
    }
    
    func backButton() {
        let button = PreviousPageButton(frame: CGRect(x: 15, y: 25, width: 40, height: 40))
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
    
    func didLoadGPXFile(gpxRoot: GPXRoot) {
        
        map.importFromGPXRoot(gpxRoot)
        
        map.regionToGPXExtent()
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
    
    // MARK: - Polyline -
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    func updatePolylineColor() {
        
        for overlay in map.overlays where overlay is MKPolyline {
            
            map.removeOverlay(overlay)
            
            map.addOverlay(overlay)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        
        LKProgressHUD.dismiss()
    }
    
    // 改成 instantiate storybroad 然後改寫成 closure 的方式把資料傳過去, 去看作業的 passValue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.userRecord.rawValue {
            if let nextVC = segue.destination as? RideViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                    
                }
            }
        }
    }
}
