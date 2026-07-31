import XCTest
@testable import PortGuard

final class EtimeParserTests: XCTestCase {

    func testSecondsOnly() {
        XCTAssertEqual(EtimeParser.parseSeconds("45"), 45)
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(EtimeParser.parseSeconds("05:09"), 5 * 60 + 9)
    }

    func testHoursMinutesAndSeconds() {
        XCTAssertEqual(EtimeParser.parseSeconds("01:05:09"), 3_600 + 5 * 60 + 9)
    }

    func testDaysHoursMinutesAndSeconds() {
        let expected: Double = 262809  // 3 * 86_400 + 3_600 + 5 * 60 + 9
        XCTAssertEqual(EtimeParser.parseSeconds("3-01:05:09"), expected)
    }

    func testDaysWithoutHours() {
        let expected: Double = 10 * 86_400
        XCTAssertEqual(EtimeParser.parseSeconds("10-00:00"), expected)
    }

    func testEmptyOrMalformedInputReturnsZero() {
        XCTAssertEqual(EtimeParser.parseSeconds(""), 0)
        XCTAssertEqual(EtimeParser.parseSeconds("   "), 0)
    }
}
