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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textAlignment = .right
        self.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.textColor = UIColor.B5
        self.distance = 0.00
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    private var _distance = 0.0

    open var distance: CLLocationDistance {
        get {
            return _distance
        }
        set {
            _distance = newValue
            text = newValue.toDistance()
            print("\(newValue)")
        }
    }
}
