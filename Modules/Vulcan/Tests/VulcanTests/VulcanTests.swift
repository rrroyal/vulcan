import XCTest
@testable import Vulcan

final class VulcanTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Vulcan().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
