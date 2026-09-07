// Tests/ZwimmTests/SwimScheduleTests.swift
import XCTest
@testable import Zwimm

class SwimScheduleTests: XCTestCase {
    func testParseSchedule() {
        let schedule = SwimSchedule()
        let result = schedule.parseSchedule(data: "Line1\nLine2\nLine3")
        XCTAssertEqual(result.count, 3)
    }
}
