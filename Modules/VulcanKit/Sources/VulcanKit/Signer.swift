import Foundation
import CryptoKit

public extension VulcanKit {
	struct Signer {
		static public func getSignatureValues(body: Data?, url: String, date: Date = Date(), privateKey: SecKey, fingerprint: String) -> (digest: String?, canonicalURL: String, signature: String)? {
			// Canonical URL
			guard let canonicalURL = getCanonicalURL(url) else {
				return nil
			}
			
			// Digest
			let digest: String?
			if let body = body {
				digest = Data(SHA256.hash(data: body)).base64EncodedString()
			} else {
				digest = nil
			}
			
			// Headers & values
			let headersList = getHeadersList(digest: digest, canonicalURL: canonicalURL, date: date)
			
			// Signature value
			guard let data = headersList.values.data(using: .utf8) else {
				return nil
			}
			
			let signatureData = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, nil) as Data?
			guard let signatureValue = signatureData?.base64EncodedString() else {
				return nil
			}
			
			return (
				digest,
				canonicalURL,
				"keyId=\"\(fingerprint.replacingOccurrences(of: ":", with: ""))\",headers=\"\(headersList.headers)\",algorithm=\"sha256withrsa\",signature=Base64(SHA256withRSA(\(signatureValue)))"
			)
		}
		
		// MARK: - Private functions
		
		/// Finds and encodes the first canonical URL match in the supplied URL.
		/// - Parameter url: URL to find matches in
		/// - Returns: Canonical URL
		static internal func getCanonicalURL(_ url: String) -> String? {
			guard let regex = try? NSRegularExpression(pattern: "(api/mobile/.+)") else {
				return nil
			}
			
			let results = regex.matches(in: url, range: NSRange(url.startIndex..., in: url))
			return results.compactMap {
				guard let range = Range($0.range, in: url) else {
					return nil
				}
				
				return String(url[range]).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?.lowercased()
			}
			.first
		}
		
		/// Creates a tuple with formatted headers and values needed to sign the request.
		/// - Parameters:
		///   - body: Body of the request
		///   - digest: Digest of the request
		///   - canonicalURL: Canonical URL of the request
		///   - date: Date of the request
		/// - Returns: Formatted headers and values
		static internal func getHeadersList(digest: String?, canonicalURL: String, date: Date) -> (headers: String, values: String) {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
			dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
			
			let dateString = "\(dateFormatter.string(from: date)) GMT"
			
			let signData: [(key: String, value: String)] = [
				("vCanonicalUrl", canonicalURL),
				digest == nil ? nil : ("Digest", digest ?? ""),
				("vDate", "\(dateString)")
			]
			.compactMap { $0 }
			
			let headers = signData.map(\.key).joined(separator: " ")
			let values = signData.map(\.value).joined()
			
			return (headers, values)
		}
	}
}
