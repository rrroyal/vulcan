//
//  String.swift
//  vulcan
//
//  Created by royal on 05/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
	var base64Decoded: String? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		
		return String(data: data, encoding: .utf8)
	}
	
	var base64Encoded: String {
		return Data(self.utf8).base64EncodedString()
	}
	
	var sha1: String {
		let data = Data(self.utf8)
		var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
		
		data.withUnsafeBytes {
			_ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
		}
		
		let hexBytes = digest.map { String(format: "%02hhx", $0) }
		return hexBytes.joined()
	}
	
	func capitalingFirstLetter() -> String {
		return prefix(1).capitalized + dropFirst()
	}
}
