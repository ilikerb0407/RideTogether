//
//  Date+Time.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/12.
//
import Foundation

extension Date {
  
    func timeAgo(numericDates: Bool) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = self < now ? self : now
        let latest =  self > now ? self : now
        
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfMonth, .month, .year, .second]
        let components: DateComponents = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        if let year = components.year {
            if year >= 2 {
                return String(format: NSLocalizedString("T_YEARS_AGO", comment: ""), year)
            } else if year >= 1 {
                return numericDates ? NSLocalizedString("T_YEAR_AGO", comment: "") : NSLocalizedString("T_LAST_YEAR", comment: "")
            }
        }
        if let month = components.month {
            if month >= 2 {
                return String(format: NSLocalizedString("T_MONTHS_AGO", comment: ""), month)
            } else if month >= 1 {
                let monthAgo = NSLocalizedString("T_MONTH_AGO", comment: "")
                let lastMonth = NSLocalizedString("T_LAST_MONTH", comment: "")
                return numericDates ? monthAgo : lastMonth
            }
        }
        if let weekOfMonth = components.weekOfMonth {
            if weekOfMonth >= 2 {
                return String(format: NSLocalizedString("T_WEEKS_AGO", comment: ""), weekOfMonth)
            } else if weekOfMonth >= 1 {
                return numericDates ? NSLocalizedString("T_WEEK_AGO", comment: "") : NSLocalizedString("T_LAST_WEEK", comment: "")
            }
        }
        if let day = components.day {
            if day >= 2 {
                return String(format: NSLocalizedString("T_DAYS_AGO", comment: ""), day)
            } else if day >= 1 {
                return numericDates ? NSLocalizedString("T_DAY_AGO", comment: "") : NSLocalizedString("T_YESTERDAY", comment: "")
            }
        }
        if let hour = components.hour {
            if hour >= 2 {
                return String(format: NSLocalizedString("T_HOURS_AGO", comment: ""), hour)
            } else if hour >= 1 {
                return numericDates ? NSLocalizedString("T_HOUR_AGO", comment: "") : NSLocalizedString("T_LAST_HOUR", comment: "")
            }
        }
        if let minute = components.minute {
            if minute >= 2 {
                return String(format: NSLocalizedString("T_MINUTES_AGO", comment: ""), minute)
            } else if minute >= 1 {
                return numericDates ? NSLocalizedString("T_MINUTE_AGO", comment: "") : NSLocalizedString("T_LAST_MINUTE", comment: "")
            }
        }
        if let second = components.second {
            if second >= 3 {
                return String(format: NSLocalizedString("T_SECONDS_AGO", comment: ""), second)
            }
        }
        return NSLocalizedString("T_JUST_NOW", comment: "")
    }
}
