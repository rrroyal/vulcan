//
//  VulcanStore.swift
//  TestApp
//
//  Created by royal on 24/12/2020.
//

import Combine
import VulcanKit

final class VulcanStore: ObservableObject {
	static let shared: VulcanStore = VulcanStore()

	let vulcanKit: VulcanKit?
	private init() {
		// Check for stored certificate
		guard let certificate: X509 = try? X509(serialNumber: 1, certificateEntries: ["CN": "APP_CERTIFICATE CA Certificate"]) else {
			vulcanKit = nil
			return
		}
		
		vulcanKit = VulcanKit(certificate: certificate)
	}
	
	public func login(token: String, symbol: String, pin: String, deviceModel: String, completionHandler: @escaping (Error?) -> Void) {
		vulcanKit?.login(token: token, symbol: symbol, pin: pin, deviceModel: deviceModel) { error in
			if error == nil {
				// Success - save certificate
			} else {
				// Error - discard or try again
			}
			
			completionHandler(error)
		}
	}
}
