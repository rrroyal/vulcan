import Foundation

extension Date {
	func formattedString(_ format: String) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = format
		return formatter.string(from: self)
	}
	
	var millisecondsSince1970: Int64 {
		Int64((self.timeIntervalSince1970 * 1000.0).rounded())
	}
}
