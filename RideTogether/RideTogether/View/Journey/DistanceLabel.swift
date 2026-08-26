//
//  DistanceLabel.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import MapKit
import UIKit

open class DistanceLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .right
        font = UIFont.systemFont(ofSize: 20, weight: .regular)
        textColor = UIColor.B5
        distance = 0.00
    }

    public required init?(coder aDecoder: NSCoder) {
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
