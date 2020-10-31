//
//  Dictionary.swift
//  
//
//  Created by royal on 27/08/2020.
//

import Foundation

public extension Dictionary where Key == Vulcan.MessageTag, Value == [Vulcan.Message] {
	var combined: [Vulcan.Message] {
		Array(self.values).flatMap { $0 }
	}
}
