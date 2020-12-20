//
//  URLRequest.swift
//  
//
//  Created by Kacper on 29/11/2020.
//

import Foundation

extension URLRequest {
	func signed(with certificate: X509, deviceModel: String) throws -> URLRequest {
		// Create request
		var request = self
		
		// Signing stuff
		guard let urlString = request.url?.absoluteString else {
			throw VulcanKit.APIError.urlError
		}
		
		// Get private key
		guard let privateKeyRawData = certificate.getPrivateKeyData(format: .DER),
			  let privateKeyString = String(data: privateKeyRawData, encoding: .utf8)?
				.split(separator: "\n")
				.dropFirst()
				.dropLast()
				.joined()
				.data(using: .utf8) else {
			throw VulcanKit.APIError.noPrivateKey
		}
		
		// Create SecKey
		let attributes = [
			kSecAttrKeyType: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass: kSecAttrKeyClassPrivate,
		]
		guard let privateKeyData = Data(base64Encoded: privateKeyString),
			  let secKey = SecKeyCreateWithData(privateKeyData as NSData, attributes as NSDictionary, nil) else {
			throw VulcanKit.APIError.noPrivateKey
		}
		
		// Get fingerprint
		guard let signatureValues = VulcanKit.Signer.getSignatureValues(body: request.httpBody, url: urlString, privateKey: secKey, fingerprint: certificate.getCertificateFingerprint().lowercased()) else {
			throw VulcanKit.APIError.noSignatureValues
		}
		
		let now = Date()
		var vDate: String {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
			dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
			
			return "\(dateFormatter.string(from: now.addingTimeInterval(-3600))) GMT"
		}
		
		// Headers
		request.setValue("iOS", forHTTPHeaderField: "vOS")
		request.setValue(deviceModel, forHTTPHeaderField: "vDeviceModel")
		request.setValue("1", forHTTPHeaderField: "vAPI")
		request.setValue(vDate, forHTTPHeaderField: "vDate")
		request.setValue(signatureValues.canonicalURL, forHTTPHeaderField: "vCanonicalUrl")
		request.setValue(signatureValues.signature, forHTTPHeaderField: "Signature")
		
		if let digest = signatureValues.digest {
			request.setValue("SHA-256=\(digest)", forHTTPHeaderField: "Digest")
		}
		
		return request
	}
}
