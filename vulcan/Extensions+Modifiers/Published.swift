//
//  Published.swift
//  vulcan
//
//  Created by royal on 08/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Combine

fileprivate var cancellables = [String: AnyCancellable]()

extension Published {
	init(wrappedValue defaultValue: Value, key: String) {
		let value = UserDefaults.group.object(forKey: key) as? Value ?? defaultValue
		self.init(initialValue: value)
		cancellables[key] = projectedValue.sink { val in
			UserDefaults.group.set(val, forKey: key)
		}
	}
}
