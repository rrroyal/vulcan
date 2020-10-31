//
//  File.swift
//  
//
//  Created by royal on 28/08/2020.
//

import Foundation

extension String {
	var westernArabicNumeralsOnly: String {
		String(unicodeScalars.compactMap { UnicodeScalar("0")..."9" ~= $0 ? Character($0) : nil })
	}
}
