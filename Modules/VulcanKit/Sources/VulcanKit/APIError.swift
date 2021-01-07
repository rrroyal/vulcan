import Foundation

public extension VulcanKit {
	enum APIError: Error {
		case error(reason: String)
		case jsonSerialization
		case noEndpointURL
		case noFirebaseToken
		case noCertificate
		case noPrivateKey
		case noSignatureValues
		case urlError
		
		case wrongToken
		case wrongPin
	}
}
