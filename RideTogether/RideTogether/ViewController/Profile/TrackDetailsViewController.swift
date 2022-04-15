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

//protocol sendDataToNextVc {
//    func sendData(_ inputUrl: URL)
//}

class TrackDetailsViewController: BaseViewController {

    @IBOutlet weak var map: GPXMapView!
    
    
    private let mapViewDelegate = MapViewDelegate()
    
    // 只會有一筆
    var record = Record()
    
    
    func setUp() {
        
        navigationController?.isNavigationBarHidden = true
        
        map.delegate = mapViewDelegate
        
        self.view.addSubview(map)
        
        tabBarController?.tabBar.isHidden = true
        
        backButton()
        
        praseGPXFile()
        
        // 分享到塗鴉牆button
        backToJourneyButton()
        
    }
    
    func backToJourneyButton(){
        let button = NextPageButton(frame: CGRect(x: 200, y: 200, width: 50, height: 50))
        button.addTarget(self, action: #selector(push), for: .touchUpInside)
        view.addSubview(button)
        print ("backtoJOur")
        
    }
    
    @objc func push(_ sender: UIButton) {
        
        if let journeyViewController = storyboard?.instantiateViewController(withIdentifier: "FollowJourneyViewController") as? FollowJourneyViewController {
            navigationController?.pushViewController(journeyViewController, animated: true)
            journeyViewController.record = record
            // 這一頁宣告的變數, 是下一頁的變數
        }
        print ("push")
    }
    
    
    func backButton() {
        let button = PreviousPageButton(frame: CGRect(x: 30, y: 30, width: 50, height: 50))
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func popToPreviosPage(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func praseGPXFile() {
        
        if let inputUrl = URL(string: record.recordRef) {
            
            print("TrackDetail:\(inputUrl)")
            // 送過去 follow!!
//            delegate?.sendData(record.recordRef)
            delegate?.sendData(record)
            guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return }
            
            didLoadGPXFile(gpxRoot: gpx)
        }
    }
    
    func didLoadGPXFile(gpxRoot: GPXRoot) {
        
        map.importFromGPXRoot(gpxRoot)
        
        map.regionToGPXExtent()
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.userRecord.rawValue {
            if let nextVC = segue.destination as? FollowJourneyViewController {
                if let record = sender as? Record {
                    nextVC.record = record
                    
                }
            }
        }
    }
    

}
