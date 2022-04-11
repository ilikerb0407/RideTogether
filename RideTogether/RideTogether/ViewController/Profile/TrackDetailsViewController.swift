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

class TrackDetailsViewController: UIViewController {

    
    @IBOutlet weak var map: GPXMapView!
    
    private let mapViewDelegate = MapViewDelegate()
    
    // 只會有一筆
    var record = Record()
    
    
    
    func setUp() {
        
        navigationController?.isNavigationBarHidden = true
        
        map.delegate = mapViewDelegate
        
        view.addSubview(map)
        
        tabBarController?.tabBar.isHidden = true
        
        backButton()
        
//        praseGPXFile()
        
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
        let url = URL(string: record.recordRef)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    


}
