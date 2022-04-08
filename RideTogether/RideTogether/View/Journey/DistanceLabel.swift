//
//  DistanceLabel.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import UIKit
import MapKit

open class DistanceLabel: UILabel {
    
    private var _distance = 0.0

    open var distance: CLLocationDistance {
        get {
            return _distance
        }
        set {
            _distance = newValue
            text = newValue.toDistance()
        }
    }
}
