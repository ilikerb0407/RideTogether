//
//  StopWatch.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation

enum StopWatchStatus {
    case started

    case stopped
}

class StopWatch: NSObject {
    var tmpElapsedTime: TimeInterval = 0.0

    var startedTime: TimeInterval = 0.0

    var status: StopWatchStatus

    var timeInterval: TimeInterval = 1.00

    var timer = Timer()

    weak var delegate: StopWatchDelegate?

    override init() {
        tmpElapsedTime = 0.0

        status = StopWatchStatus.stopped

        super.init()
    }

    func start() {
        status = .started

        startedTime = Date.timeIntervalSinceReferenceDate

        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(StopWatch.updateElapsedTime),
                                     userInfo: nil, repeats: true)
    }

    func stop() {
        status = .stopped

        let currentTime = Date.timeIntervalSinceReferenceDate

        let diff = currentTime - startedTime

        tmpElapsedTime += diff

        timer.invalidate()
    }

    func reset() {
        timer.invalidate()

        tmpElapsedTime = 0.0

        startedTime = Date.timeIntervalSinceReferenceDate

        status = .stopped
    }

    var elapsedTime: TimeInterval {
        if status == .stopped {
            return tmpElapsedTime
        }

        let diff = Date.timeIntervalSinceReferenceDate - startedTime

        return tmpElapsedTime + diff
    }

    var elapsedTimeString: String {
        var tmpTime: TimeInterval = elapsedTime

        let hours = UInt32(tmpTime / 3600.0)
        tmpTime -= (TimeInterval(hours) * 3600)

        let minutes = UInt32(tmpTime / 60.0)
        tmpTime -= (TimeInterval(minutes) * 60)

        let seconds = UInt32(tmpTime)
        tmpTime -= TimeInterval(seconds)

        let strHours = hours > 0 ? String(hours) + "h" : ""

        let strMinutes = minutes > 9 ? String(minutes) : "0" + String(minutes)

        let strSeconds = seconds > 9 ? String(seconds) : "0" + String(seconds)

        return "\(strHours)\(strMinutes):\(strSeconds)"
    }

    @objc func updateElapsedTime() {
        delegate?.stopWatch(self, didUpdateElapsedTimeString: elapsedTimeString)
    }
}
