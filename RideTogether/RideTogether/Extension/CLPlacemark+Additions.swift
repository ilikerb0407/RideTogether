//
//  CLPlacemark+Additions.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import CoreLocation

extension CLPlacemark {
    var abbreviation: String {
        if let name = self.name {
            return name
        }

        if let interestingPlace = areasOfInterest?.first {
            return interestingPlace
        }

        return [subThoroughfare, thoroughfare].compactMap { $0 }.joined(separator: " ")
    }
}
