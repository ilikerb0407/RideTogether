//
//  TimeInterval+Additions.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import Foundation

extension TimeInterval {
  var formatted: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.hour, .minute]

    return formatter.string(from: self) ?? ""
  }
}
