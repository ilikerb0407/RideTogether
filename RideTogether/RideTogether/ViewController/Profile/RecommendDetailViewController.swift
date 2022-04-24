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

class RecommendDetailViewController: UIViewController {
    
    
    @IBOutlet weak var map2: GPXMapView!
    
    private let mapViewDelegate = MapViewDelegate()
    
    // 只會有一筆
    var record = Record()
    
    func setUp() {
        
        navigationController?.isNavigationBarHidden = true
        
        map2.delegate = mapViewDelegate
        
        self.view.addSubview(map2)
        
        tabBarController?.tabBar.isHidden = true
        
        backButton()
        
        praseGPXFile()
        
//        rideButton()
        
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
            
            guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return }
            
            didLoadGPXFile(gpxRoot: gpx)
            
        }
    }

    
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
    
}
