//
//  Array.swift
//  vulcan
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
	var uniques: Array {
		var buffer = Array()
		var added = Set<Element>()
		for elem in self {
			if !added.contains(elem) {
				buffer.append(elem)
				added.insert(elem)
			}
		}
		return buffer
	}
}
