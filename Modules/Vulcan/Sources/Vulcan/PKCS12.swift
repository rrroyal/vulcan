//
//  PKCS12.swift
//  vulcan
//
//  Created by royal on 05/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import Security

class PKCS12 {
	let privateKey: SecKey
	let publicKey: SecKey?
	
	enum PKCS12Error: Error {
		case loadError(message: String)
	}
	
	init(certificate: Data, password: String) throws {
		let identityAndTrust = try PKCS12.identityAndTrust(data: certificate, password: password)
		
		self.privateKey = try PKCS12.privateKey(for: identityAndTrust.identity)
		self.publicKey = PKCS12.publicKey(for: identityAndTrust.trust)
	}
	
	class func identityAndTrust(data: Data, password: String) throws -> (identity: SecIdentity, trust: SecTrust) {
		var importResult: CFArray?
		
		let status = SecPKCS12Import(
			data as NSData,
			[kSecImportExportPassphrase as String: password] as NSDictionary,
			&importResult
		)
		
		guard (status == errSecSuccess) else {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
		}
		
		guard let identityDictionaries = importResult as? [[String: Any]] else {
			throw PKCS12.PKCS12Error.loadError(message: "Unable to load the certificate")
		}
		
		let identity = identityDictionaries[0][kSecImportItemIdentity as String] as! SecIdentity
		let trust = identityDictionaries[0][kSecImportItemTrust as String] as! SecTrust
		
		return (identity: identity, trust: trust)
	}
	
	class func privateKey(for identity: SecIdentity) throws -> SecKey {
		var privateKey: SecKey?
		let status = SecIdentityCopyPrivateKey(identity, &privateKey)
		
		guard (status == errSecSuccess) else {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
		}
		
		return privateKey!
	}
	
	class func publicKey(for trust: SecTrust) -> SecKey? {
		return SecTrustCopyKey(trust)
	}
	
	public func signData(data: NSData) -> String? {
		var signature: String?
		var error: Unmanaged<CFError>?
		
		guard let signedData = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA1, data as CFData, &error) as Data? else {
			return nil
		}
		signature = signedData.base64EncodedString()
		
		return signature
	}
}
