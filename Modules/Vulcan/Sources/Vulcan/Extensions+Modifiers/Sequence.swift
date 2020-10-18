//
//  Sequence.swift
//  
//
//  Created by Kacper on 18/10/2020.
//

import Foundation

extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		return sorted { a, b in
			return a[keyPath: keyPath] < b[keyPath: keyPath]
		}
	}
}
