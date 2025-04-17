//
//  DistanceLabel.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import MapKit
import UIKit

open class DistanceLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textAlignment = .right
        self.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.textColor = UIColor.B5
        self.distance = 0.00
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textAlignment = .right
        self.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.textColor = UIColor.B5
        self.distance = 0.00
    }

    private var _distance: Double = 0.0

    open var distance: CLLocationDistance {
        get {
            _distance
        }
        set {
            _distance = newValue
            text = newValue.toDistance()
            print("\(newValue)")
        }
    }
}
