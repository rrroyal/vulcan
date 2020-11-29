import XCTest
@testable import VulcanKit

final class VulcanKitTests: XCTestCase {
	
	// MARK: - Variables
	
	struct TestData {
		static let body: Data = "{}".data(using: .utf8)!
		static let fullURL: String = "/powiatwulkanowy/123456/api/mobile/register/hebe"
		static let date: Date = Date(timeIntervalSince1970: 1586837656)
		static let fingerprint: String = "7EBA57E1DDBA1C249D097A9FF1C9CCDD45351A6A"
		static let privateKeyBase64: String = "MIIEpAIBAAKCAQEAwmxeU7de+hKQeHF+VPj2RNF8rYyfQAQ2RWgRQ5GnsW5LjXrizmgEY0BDpVKAZqWUF8QBfB5WKnk7z4k3J0n0CEuhHaqSArkDXcL8ughxQHtoppG2wdGhz7Bnqesx/GcR27LGs5EwpxstI9mbRk9v4stRhL3P6dmzpAlXEdR9Rqhafv16X2jMItkkQsHOuyvBbvE40gyjb3EU/Z7npxqDwNQlqDojgsYUAOoJwfC1Cz3pek1Q8XgVXWKK/89hsRXv5tKWu1wCs73rlA4R/JPDZTRuuTI72YYMvYhbPngVKu5QmdJ7iLA8451Ky0peHImCo/XfeKq1MhfC/A/UZftFpQIDAQABAoIBAEOo4N6zZssSINK5dGRvy4xBdukSkez+SkC3KaLhEoGtx38x77IzAqvjlmb3IhYWs0XeAUJHcGcRj532u4nhs5obb7NaQ7vM1P4ROFApVfhBujaVaQtkP7J+SmUYo2maGN3jBkFBWrQcwgXC2cWLKX28kd7nC27vQxPn6DQdRYeLvUQg492wpU7Kj3DQSGizKWK93/2zNXxW0vS6yewF2ULRoP9jB+fFrL1eu0omAEKhgs5Xfyae+IJqHeCItMNl1meznosXRdsa9Y+0ytHVFJa6zq29XIDlkjhF8st0V/4he0fLri14kX6NVEYelTT6DrawunxwqwqdYkQaNPKjpOECgYEA8ai61gO4CnE69skHhnxE1zgGItMamzY+QPXlQtF54MZxbsFnOc8oNz7N3NFCtqk0khb+EqHhB0DPlNPvS42MyEUlB+88uMwawZS7U0AsrErrmfUH4DueW9/0BGJMseh8/8/4IOd4yh47FCiH7RjMCegtTNrL2wTWArFq1LmHLG0CgYEAzfYJFQwASHllLSgx8geRxnFW7IOyYuxoTI3RQNBgfvZEdHaCjXLa88Sp+uQSNrk1oPpsWsOVflHiTiGnhbL9rgpWCWJ9ReeVU+zSMdwixb+sxUUojEis9lvjZMBo0Kkew9w3hMmpaY3kHjHaR2YNuyzG3VZM8v3CvBDPWUJUSxkCgYEAqQdsJ+XSBPvOUm+qY9boD+GP6SvfoFEAmk9kXKhIp4AmN2Hv4e+UIZA8TgfQshMIQmbyr/WqgHhEucTDzATmQ+6ZSEN+JYQd8uklXcW1eY2t3bIWIDGTQpATDj3zhz0msYe19s3xHu6mRCNVb/G4RfWwOeGQVVG8n4WZQ9HBSsECgYEAvQZ1x29AQ0PG6+7cB/mSfMJAuMkVy1yVTM1Lo2Sba2qx4QFzSEaFVPzF1JHFdZv98ERlddfTOCAGxxZ0HWztDfJGjE5sEuA8WM4dC82xzDPiaRrT4AxDUcd7p1g/2mGc7r0J50D9zvZ+yoeOgcDUEVlDGpi9/rWPJ/N1mcIaguECgYAU1Mx8tLBBGd4WIMFNsoG8wtLz5WncNiqrSsvtC3R7ceaahOP6b4VTKUUUzQQ4gL2+ZWZjAfwdws6IjEDsHM7rrPF7Me2xHItvA80PoNs7dP2wtl5fvfdgLLOTz+TbTqz//UIkzYKBUgq1Z2Zzc0KqYwqxbI3zg9n4rhSwg+s4ug=="
	}
	
	var secKey: SecKey {
		// initialize key
		let parameters = [
			kSecAttrKeyType: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass: kSecAttrKeyClassPrivate,
		]
		
		return SecKeyCreateWithData(Data(base64Encoded: TestData.privateKeyBase64)! as NSData, parameters as NSDictionary, nil)!
	}
	var signatureValues: (digest: String?, canonicalURL: String, signature: String)? {
		VulcanKit.Signer.getSignatureValues(body: TestData.body, url: TestData.fullURL, date: TestData.date, privateKey: secKey, privateKeyFingerprint: TestData.fingerprint)
	}
	
	// MARK: - Tests
	
	func testDigest() {
		let expected = "SHA-256=RBNvo1WzZ4oRRq0W9+hknpT7T8If536DEMBg9hyq/4o="
		XCTAssertEqual("SHA-256=\(signatureValues?.digest ?? "")", expected)
	}
	
	func testCanonicalURL() {
		let expected = "api%2fmobile%2fregister%2fhebe"
		XCTAssertEqual(signatureValues?.canonicalURL, expected)
	}
	
	func testSignature() {
		let expected = "keyId=\"7EBA57E1DDBA1C249D097A9FF1C9CCDD45351A6A\"," +
			"headers=\"vCanonicalUrl Digest vDate\"," +
			"algorithm=\"sha256withrsa\"," +
			"signature=Base64(SHA256withRSA(mIVNkthTzTHmmXG1qxv1Jpt3uRlyhbj7VHysbCNpl0zXCCzuwTXsuCrfjexDDXsyJVo/LznQKOyvOaW4tEfrBobxtbtTnp7zYi54bdvAZa3pvM02yvkH4i/DvTLDKRO0R9UDZ1LraGrOTsIe3m3mQ21NOynVqCKadeqod8Y7l4YUlVYEmrtq/7xbCwr0qdne6G67eY4Amj6ffbG3TkVLpUrEETBnAC7oFjGYKhcRyvltAi+lcv6omANz1gwELf+Vmsa8NwFo/YGwY3R23z15athU/1iC1JcrECBLC8nRM1+KlvyIqx2HX6RG5R1cMOwBWVg6pRKUdrhxYbQ+VQ8Cag==))"
		
		XCTAssertEqual(signatureValues?.signature, expected)
	}
	
	static var allTests = [
		("testDigest", testDigest),
		("testCanonicalURL", testCanonicalURL),
		("testSignature", testSignature)
	]
}
