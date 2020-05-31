//
//  Date.swift
//  vulcan
//
//  Created by royal on 05/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension Date {
	static func - (lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
	
	func formattedString(format: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		dateFormatter.locale = Locale.current
		
		return dateFormatter.string(from: self)
	}
	
	func startOfTheYear(offset: Int = 0) -> Date? {
		let currentYear = Calendar.current.component(.year, from: self)
		return Calendar.current.date(from: DateComponents(year: currentYear + offset, month: 1, day: 1))
	}
	
	func endOfTheYear(offset: Int = 0) -> Date? {
		let currentYear = Calendar.current.component(.year, from: self)
		return Calendar.current.date(from: DateComponents(year: currentYear + offset, month: 12, day: 31))
	}
	
	var helloString: String {
		let hour: Int = Calendar.current.component(.hour, from: self)
		var hello: String = "HELLO"
		
		if (hour >= 4 && hour < 13) {
			hello = "GOOD_MORNING"
		} else if (hour >= 13 && hour < 18) {
			hello = "GOOD_AFTERNOON"
		} else if ((hour >= 18 && hour < 24) || (hour >= 0 && hour < 4)) {
			hello = "GOOD_EVENING"
		}
		
		return hello
	}
	
	var timestampString: String? {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .abbreviated
		formatter.maximumUnitCount = 2
		formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		
		guard let timeString = formatter.string(from: self, to: Date()) else {
			return nil
		}
		
		let formatString = NSLocalizedString("%@", comment: "")
		return String(format: formatString, timeString)
	}
	
	var localizedTime: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .short
		return dateFormatter.string(from: self)
	}
	
	var startOfWeek: Date? {
		let calendar = Calendar(identifier: .gregorian)
		guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
		return calendar.date(byAdding: .day, value: 1, to: sunday)
	}
	
	var endOfWeek: Date? {
		let calendar = Calendar(identifier: .gregorian)
		guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
		return calendar.date(byAdding: .day, value: 7, to: sunday)
	}
	
	var startOfMonth: Date {
		let calendar = Calendar(identifier: .gregorian)
		let components = calendar.dateComponents([.year, .month], from: self)
		return calendar.date(from: components)!
	}
	
	var endOfMonth: Date {
		var components = DateComponents()
		components.month = 1
		components.second = -1
		return Calendar(identifier: .gregorian).date(byAdding: components, to: self.startOfMonth)!
	}
}
