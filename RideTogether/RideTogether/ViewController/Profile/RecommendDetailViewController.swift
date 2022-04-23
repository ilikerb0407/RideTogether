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
    

    @IBOutlet weak var map: GPXMapView!
    
    
    private let mapViewDelegate = MapViewDelegate()
    
    // 只會有一筆
    var record = SharedMap()
    
    func setUp() {
        
        navigationController?.isNavigationBarHidden = true
        
        map.delegate = mapViewDelegate
        
        self.view.addSubview(map)
        
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
    
}
