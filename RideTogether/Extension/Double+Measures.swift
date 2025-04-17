//
//  Double+Measures.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation

let metersPerKilometer = 1000.0

let kilometersPerHourInOneMeterPerSecond = 3.6

extension Double {
    func toKilometers() -> Double {
        self / metersPerKilometer
    }

    func toKilometers() -> String {
        String(format: "%.2f 公里", toKilometers() as Double)
    }

    func toMeters() -> String {
        String(format: "%.0f 公尺", self as Double)
    }

    func toDistance() -> String {
        if self > 1000 {
            return toKilometers() as String
        } else {
            return toMeters() as String
        }
    }

    // MARK: transfer m/s to km/h
    func toKilometersPerHour() -> Double {
        self * kilometersPerHourInOneMeterPerSecond
    }

    func toKilometersPerHour() -> String {
        String(format: "%.1f 里/時", toKilometersPerHour() as Double)
    }

    func toSpeed() -> String {
        toKilometersPerHour() as String
    }

    func toAltitude() -> String {
        String(format: "%.1f公尺", self)
    }

    func toAccuracy(useImperial _: Bool = false) -> String {
        "±\(toMeters() as String)"
    }

    func tohmsTimeFormat() -> String {
        let seconds = Int(self)

        let hour = seconds / 3600

        let minute = (seconds % 3600) / 60

        let second = (seconds % 3600) % 60

        var timeString = ""

        timeString += hour.description

        timeString += ":"

        timeString += minute.description

        timeString += ":"

        timeString += second.description

        return timeString
    }

    func sunrise() -> String {
        let seconds = Int(self)

        let hour = (seconds % 3600) % 7

        let minute = (seconds % 3600) / 60

        var timeString = ""

        timeString += hour.description

        timeString += ":0"

        timeString += minute.description

        return timeString
    }

    func sunset() -> String {
        let seconds = Int(self)

        let hour = (seconds % 3600) % 7

        let minute = (seconds % 3600) / 60

        var timeString = ""

        timeString += hour.description

        timeString += ":"

        timeString += minute.description

        return timeString
    }

    func roundDouble() -> String {
        String(format: "%.0f", self)
    }
}

extension String {
    func removeFileSuffix() -> String {
        var components = self.components(separatedBy: ".")

        if components.count > 1 {
            components.removeLast()

            return components.joined(separator: ".")

        } else {
            return self
        }
    }
}
