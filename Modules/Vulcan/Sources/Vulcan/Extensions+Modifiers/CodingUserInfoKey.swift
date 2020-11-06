//
//  CodingUserInfoKey.swift
//  
//
//  Created by Kacper on 05/11/2020.
//

import Foundation

public extension CodingUserInfoKey {
	static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

public enum DecoderConfigurationError: Error {
	case missingManagedObjectContext
}
