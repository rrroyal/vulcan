import Foundation
import CryptoKit
import OpenSSL

public class X509 {
	enum X509Error: Error {
		case errorGeneratingPKEY
	}
	
	public enum KeyFormat {
		case PEM
		case DER
	}
	
	let certificate: OpaquePointer
	let pkey: OpaquePointer
	
	public init(serialNumber: Int, certificateEntries: [String: String]) throws {
		let x509: OpaquePointer = X509_new()
		
		// serial number
		ASN1_INTEGER_set(X509_get_serialNumber(x509), serialNumber)
		
		// version
		X509_set_version(x509, 0x2)	// v3
		
		// validity date
		X509_gmtime_adj(X509_getm_notBefore(x509), 0)
		X509_gmtime_adj(X509_getm_notAfter(x509), 60 * 60 * 24 * 365 * 10)	// 60 seconds * 60 minutes * 24 hours * 365 days * 10 years
		
		// key
		guard let pkey = EVP_PKEY_new() else {
			throw X509Error.errorGeneratingPKEY
		}
		
		let exponent = BN_new()
		BN_set_word(exponent, 0x10001)
		
		let rsa = RSA_new()
		RSA_generate_key_ex(rsa, 2048, exponent, nil)
		EVP_PKEY_set1_RSA(pkey, rsa)
		
		X509_set_pubkey(x509, pkey)
		self.pkey = pkey
		
		// issuer
		let subjectName = X509_get_subject_name(x509)
		for (key, value) in certificateEntries {
			X509_NAME_add_entry_by_txt(subjectName, key, MBSTRING_ASC, value, -1, -1, 0)
		}
		
		X509_set_issuer_name(x509, subjectName)
		
		// sign the certificate
		X509_sign(x509, pkey, EVP_sha256())
		
		self.certificate = x509
	}
	
	/// Gets the private key used to sign the certificate data.
	/// - Parameter format: Format of the returned key
	/// - Returns: Private key data
	public func getPrivateKeyData(format: KeyFormat) -> Data? {
		let bio = BIO_new(BIO_s_mem())
		
		switch format {
			case .PEM:	PEM_write_bio_PrivateKey(bio, self.pkey, nil, nil, 0, nil, nil)
			case .DER:	PEM_write_bio_PrivateKey_traditional(bio, self.pkey, nil, nil, 0, nil, nil)
		}

		var pointer: UnsafeMutableRawPointer?
		let len = BIO_ctrl(bio, BIO_CTRL_INFO, 0, &pointer)
		
		guard let nonEmptyPointer = pointer else {
			return nil
		}
		
		let data = Data(bytes: nonEmptyPointer, count: len)
		BIO_vfree(bio)
				
		return data
	}
	
	/// Gets the public key used to sign the certificate data.
	/// - Returns: Public key data
	public func getPublicKeyData() -> Data? {
		let bio = BIO_new(BIO_s_mem())
		PEM_write_bio_PUBKEY(bio, self.pkey)
		
		var pointer: UnsafeMutableRawPointer?
		let len = BIO_ctrl(bio, BIO_CTRL_INFO, 0, &pointer)
		
		guard let nonEmptyPointer = pointer else {
			return nil
		}
		
		let data = Data(bytes: nonEmptyPointer, count: len)
		BIO_vfree(bio)
		
		return data
	}
	
	/// Gets the generated certificate data.
	/// - Returns: Certificate data
	public func getCertificateData() -> Data? {
		let bio = BIO_new(BIO_s_mem())
		PEM_write_bio_X509(bio, self.certificate)
		
		var pointer: UnsafeMutableRawPointer?
		let len = BIO_ctrl(bio, BIO_CTRL_INFO, 0, &pointer)
		
		guard let nonEmptyPointer = pointer else {
			return nil
		}
		
		let data = Data(bytes: nonEmptyPointer, count: len)
		BIO_vfree(bio)
		
		return data
	}
	
	/// Get certificate thumbrint.
	/// - Returns: Certificate fingerprint
	public func getCertificateFingerprint() -> String {
		let md: UnsafeMutablePointer<UInt8> = .allocate(capacity: Int(EVP_MAX_MD_SIZE))
		var n: UInt32 = 0
		
		X509_digest(self.certificate, EVP_sha1(), md, &n)
		return UnsafeMutableBufferPointer(start: md, count: Int(EVP_MAX_MD_SIZE))
			.prefix(Int(n))
			.makeIterator()
			.map {
				let string = String($0, radix: 16)
				return ($0 < 16 ? "0" + string : string)
			}
			.joined(separator: ":")
			.uppercased()
	}
	
	/// Get public key fingerprint
	/// - Returns: Public key fingerprint
	public func getPublicKeyFingerprint() -> String? {
		guard let keyData = self.getPublicKeyData(),
			  let rawKeyB64 = String(data: keyData, encoding: .utf8) else {
			return nil
		}
		
		let keyB64 = rawKeyB64
			.split(separator: "\n")	// Split by newline
			.dropFirst()			// Drop prefix
			.dropLast()				// Drop suffix
			.joined()				// Combine
		
		guard let data = Data(base64Encoded: keyB64) else {
			return nil
		}
		
		let hash = Insecure.MD5.hash(data: data)
		return hash.map { String(format: "%02hhx", $0) }.joined()
	}
	
	/// Get private key fingerprint
	/// - Parameter format: Format of the returned key
	/// - Returns: Private key fingerprint
	public func getPrivateKeyFingerprint(format: KeyFormat) -> String? {
		guard let keyData = self.getPrivateKeyData(format: format),
			  let rawKeyB64 = String(data: keyData, encoding: .utf8) else {
			return nil
		}
		
		let keyB64 = rawKeyB64
			.split(separator: "\n")	// Split by newline
			.dropFirst()			// Drop prefix
			.dropLast()				// Drop suffix
			.joined()				// Combine
		
		guard let data = Data(base64Encoded: keyB64) else {
			return nil
		}
		
		let hash = Insecure.MD5.hash(data: data)
		return hash.map { String(format: "%02hhx", $0) }.joined()
	}
}
