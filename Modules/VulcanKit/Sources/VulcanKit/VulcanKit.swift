import Foundation
import Combine
import os

public class VulcanKit {
	static private let libraryVersion: String = "v0-INTERNAL"
	
	private let loggerSubsystem: String = "xyz.shameful.VulcanKit"
	private var cancellables: Set<AnyCancellable> = []
	
	public let certificate: X509
	
	// MARK: - Init
	public init(certificate: X509) {
		self.certificate = certificate
	}
	
	// MARK: - Public functions
	
	/// Logs in with supplied login data.
	/// - Parameters:
	///   - token: Login token
	///   - symbol: Login symbol
	///   - pin: Login PIN
	///   - deviceName: Name of the device
	///   - completionHandler: Callback
	public func login(token: String, symbol: String, pin: String, deviceModel: String, completionHandler: @escaping (Error?) -> Void) {
		let logger: Logger = Logger(subsystem: self.loggerSubsystem, category: "Login")
		logger.debug("Logging in...")
		
		let endpointPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: "http://komponenty.vulcan.net.pl/UonetPlusMobile/RoutingRules.txt")!)
			.mapError { $0 as Error }
		
		// Firebase request
		var firebaseRequest: URLRequest = URLRequest(url: URL(string: "https://android.googleapis.com/checkin")!)
		firebaseRequest.httpMethod = "POST"
		firebaseRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
		firebaseRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		let firebaseRequestBody: [String: Any] = [
			"locale": "pl_PL",
			"digest": "",
			"checkin": [
				"iosbuild": [
					"model": deviceModel,
					"os_version": Self.libraryVersion
				],
				"last_checkin_msec": 0,
				"user_number": 0,
				"type": 2
			],
			"time_zone": TimeZone.current.identifier,
			"user_serial_number": 0,
			"id": 0,
			"logging_id": 0,
			"version": 2,
			"security_token": 0,
			"fragment": 0
		]
		firebaseRequest.httpBody = try? JSONSerialization.data(withJSONObject: firebaseRequestBody)
		
		let firebasePublisher = URLSession.shared.dataTaskPublisher(for: firebaseRequest)
			.receive(on: DispatchQueue.global(qos: .background))
			.tryCompactMap { value -> AnyPublisher<Data, Error> in
				guard let dictionary: [String: Any] = try? JSONSerialization.jsonObject(with: value.data) as? [String: Any] else {
					throw APIError.jsonSerialization
				}
				
				var request: URLRequest = URLRequest(url: URL(string: "https://fcmtoken.googleapis.com/register")!)
				request.httpMethod = "POST"
				request.setValue("AidLogin \(dictionary["android_id"] as? Int ?? 0):\(dictionary["security_token"] as? Int ?? 0)", forHTTPHeaderField: "Authorization")
				request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
				
				let body: String = "device=\(dictionary["android_id"] as? Int ?? 0)&app=pl.edu.vulcan.hebe&sender=987828170337&X-subtype=987828170337&appid=dLIDwhjvE58&gmp_app_id=1:987828170337:ios:6b65a4ad435fba7f"
				request.httpBody = body.data(using: .utf8)
				
				return URLSession.shared.dataTaskPublisher(for: request)
					.receive(on: DispatchQueue.global(qos: .background))
					.mapError { $0 as Error }
					.map { $0.data }
					.eraseToAnyPublisher()
			}
			.flatMap { $0 }
		
		Publishers.Zip(endpointPublisher, firebasePublisher)
			.tryMap { (endpoints, firebaseToken) -> (String, String) in
				// Find endpointURL
				let lines = String(data: endpoints.data, encoding: .utf8)?.split { $0.isNewline }
				
				var endpointURL: String?
				lines?.forEach { line in
					let items = line.split(separator: ",")
					if (token.starts(with: items[0])) {
						endpointURL = String(items[1])
						return
					}
				}
				
				guard let finalEndpointURL: String = endpointURL else {
					throw APIError.noEndpointURL
				}
				
				// Get Firebase token
				guard let token: String = String(data: firebaseToken, encoding: .utf8)?.components(separatedBy: "token=").last else {
					logger.error("Token empty! Response: \"\(firebaseToken.base64EncodedString(), privacy: .private)\"")
					throw APIError.noFirebaseToken
				}
				
				return (finalEndpointURL, token)
			}
			.tryMap { endpointURL, firebaseToken in
				try self.registerDevice(endpointURL: endpointURL, firebaseToken: firebaseToken, token: token, symbol: symbol, pin: pin, deviceModel: deviceModel)
					.mapError { $0 as Error }
					.map { $0.data }
					.eraseToAnyPublisher()
			}
			.flatMap { $0 }
			.sink(receiveCompletion: { completion in
				switch completion {
					case .finished:
						break
					case .failure(let error):
						completionHandler(error)
				}
			}, receiveValue: { data in
				if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
				   let parsedError = self.parseResponse(response) {
					completionHandler(parsedError)
				} else {
					completionHandler(nil)
				}
			})
			.store(in: &cancellables)
	}
	
	// MARK: - Private functions
	
	/// Registers the device
	/// - Parameters:
	///   - endpointURL: API endpoint URL
	///   - firebaseToken: FCM token
	///   - token: Vulcan token
	///   - symbol: Vulcan symbol
	///   - pin: Vulcan PIN
	///   - deviceModel: Device model
	/// - Throws: Error
	/// - Returns: URLSession.DataTaskPublisher
	private func registerDevice(endpointURL: String, firebaseToken: String, token: String, symbol: String, pin: String, deviceModel: String) throws -> URLSession.DataTaskPublisher {
		guard let keyFingerprint = certificate.getPrivateKeyFingerprint(format: .PEM)?.replacingOccurrences(of: ":", with: "").lowercased(),
			  let keyData = certificate.getPublicKeyData(),
			  let keyBase64 = String(data: keyData, encoding: .utf8)?
				.split(separator: "\n")	// Split by newline
				.dropFirst()			// Drop prefix
				.dropLast()				// Drop suffix
				.joined()				// Join
		else {
			throw APIError.noCertificate
		}
						
		// Request
		let url = "\(endpointURL)/\(symbol)/api/mobile/register/new"
		var request = URLRequest(url: URL(string: url)!)
		request.httpMethod = "POST"
		
		let now: Date = Date()
		var timestampFormatted: String {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
			
			return dateFormatter.string(from: now)
		}
				
		// Body
		let body: [String: Encodable?] = [
			"AppName": "DzienniczekPlus 2.0",
			"AppVersion": Self.libraryVersion,
			"CertificateId": nil,
			"Envelope": [
				"OS": "iOS",
				"PIN": pin,
				"Certificate": keyBase64,
				"CertificateType": "RSA_PEM",
				"DeviceModel": deviceModel,
				"SecurityToken": token,
				"SelfIdentifier": UUID().uuidString.lowercased(),
				"CertificateThumbprint": keyFingerprint
			],
			"FirebaseToken": firebaseToken,
			"API": 1,
			"RequestId": UUID().uuidString.lowercased(),
			"Timestamp": now.millisecondsSince1970,
			"TimestampFormatted": "\(timestampFormatted) GMT"
		]
		
		request.httpBody = try? JSONSerialization.data(withJSONObject: body)
		
		request.allHTTPHeaderFields = [
			"Content-Type": "application/json",
			"Accept-Encoding": "gzip",
			"vDeviceModel": deviceModel
		]
		
		let signedRequest = try request.signed(with: certificate)
		return URLSession.shared.dataTaskPublisher(for: signedRequest)
	}
	
	// MARK: - Helper functions
	
	/// Parses the response
	/// - Parameter response: Request response
	/// - Returns: VulcanKit.APIError?
	private func parseResponse(_ response: [String: Any]) -> APIError? {
		guard let status = response["Status"] as? [String: Any],
			  let statusCode = status["Code"] as? Int else {
			return nil
		}
				
		switch statusCode {
			case 0:		return nil
			case 200:	return APIError.wrongToken
			case 203:	return APIError.wrongPin
			default:	return nil
		}
	}
}
