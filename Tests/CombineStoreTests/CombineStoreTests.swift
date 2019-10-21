import XCTest
@testable import CombineStore

final class CombineStoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CombineStore().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
