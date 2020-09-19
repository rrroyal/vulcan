//
//  Date.swift
//  vulcan
//
//  Created by royal on 05/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension Date {
	public static func - (lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
	
	public func formattedString(format: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		dateFormatter.locale = Locale.autoupdatingCurrent
		
		return dateFormatter.string(from: self)
	}
	
	public func formattedDateString(timeStyle: DateFormatter.Style = .none, dateStyle: DateFormatter.Style = .none, context: DateFormatter.Context = .unknown, hideDate: Bool = false) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = timeStyle
		dateFormatter.dateStyle = (hideDate && self >= Date().startOfDay) ? .none : dateStyle
		dateFormatter.locale = Calendar.autoupdatingCurrent.locale
		dateFormatter.timeZone = Calendar.autoupdatingCurrent.timeZone
		dateFormatter.formattingContext = context
		
		return dateFormatter.string(from: self)
	}
	
	public var relativeString: String {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .none
		dateFormatter.dateStyle = .long
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter.string(from: self)
	}
	
	public var timestampString: String? {
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
	
	public var localizedTime: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .short
		return dateFormatter.string(from: self)
	}
	
	public func startOfTheYear(offset: Int = 0) -> Date? {
		let currentYear = Calendar.autoupdatingCurrent.component(.year, from: self)
		return Calendar.autoupdatingCurrent.date(from: DateComponents(year: currentYear + offset, month: 1, day: 1))
	}
	
	public func endOfTheYear(offset: Int = 0) -> Date? {
		let currentYear = Calendar.autoupdatingCurrent.component(.year, from: self)
		return Calendar.autoupdatingCurrent.date(from: DateComponents(year: currentYear + offset, month: 12, day: 31))
	}
	
	public var startOfDay: Date {
		return Calendar.autoupdatingCurrent.startOfDay(for: self)
	}
	
	public var endOfDay: Date {
		var components = DateComponents()
		components.day = 1
		components.second = -1
		return Calendar.autoupdatingCurrent.date(byAdding: components, to: startOfDay)!
	}
	
	public var startOfWeek: Date? {
		let calendar = Calendar(identifier: .gregorian)
		guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
		return calendar.date(byAdding: .day, value: 1, to: sunday)
	}
	
	public var endOfWeek: Date? {
		let calendar = Calendar(identifier: .gregorian)
		guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
		return calendar.date(byAdding: .day, value: 7, to: sunday)
	}
	
	public var startOfMonth: Date {
		let calendar = Calendar(identifier: .gregorian)
		let components = calendar.dateComponents([.year, .month], from: self)
		return calendar.date(from: components)!
	}
	
	public var endOfMonth: Date {
		var components = DateComponents()
		components.month = 1
		components.second = -1
		return Calendar(identifier: .gregorian).date(byAdding: components, to: self.startOfMonth)!
	}
}
