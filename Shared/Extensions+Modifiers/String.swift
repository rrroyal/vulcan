//
//  String.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import Foundation

extension String {
	/// Returns strings of the URLs in the current string.
	var urls: [URL]? {
		var urls : [URL] = []
		guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
			return nil
		}
		
		detector.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count), using: { result, _, _ in
			if let match = result, let url = match.url {
				urls.append(url)
			}
		})
		
		return urls
	}
	
	var base64Decoded: String? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		
		return String(data: data, encoding: .utf8)
	}
	
	var base64Encoded: String {
		return Data(self.utf8).base64EncodedString()
	}
	
	var localized: String {
		return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
	}
	
	func capitalingFirstLetter() -> String {
		return prefix(1).capitalized + dropFirst()
	}
	
	var isReallyEmpty: Bool {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
