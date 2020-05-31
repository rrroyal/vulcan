//
//  Int+Double.swift
//  vulcan
//
//  Created by royal on 18/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension Double {
	
	/// Rounds the double to decimal places value
	func rounded(toPlaces places: Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
	
}
