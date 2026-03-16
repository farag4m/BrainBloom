import Foundation
import XCTest
@testable import BrainBloom

final class RuleValidationTests: XCTestCase {
    func testScheduledWindowRejectsInvertedTimes() {
        let schedule = RuleSchedule(activeDays: Set(1...7), startHour: 18, startMinute: 0, endHour: 9, endMinute: 0)
        let result = RuleValidation.validate(mode: .scheduledWindow, allowedMinutes: 30, intervalHours: 1, schedule: schedule)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.scheduleMessage)
    }

    func testHourlyRejectsAllowanceBeyondWindow() {
        let schedule = RuleSchedule.allDayEveryDay
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 90, intervalHours: 1, schedule: schedule)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }

    func testDailyAcceptsFullDayAllowance() {
        let schedule = RuleSchedule.allDayEveryDay
        let result = RuleValidation.validate(mode: .daily, allowedMinutes: 1440, intervalHours: 1, schedule: schedule)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Hourly allowance > interval

    func testHourlyRejectsAllowanceExceedingMultiHourInterval() {
        // 130 min allowance in a 2-hour (120 min) interval
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 130, intervalHours: 2, schedule: .allDayEveryDay)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }

    func testHourlyAcceptsAllowanceEqualToInterval() {
        // Exactly 60 min in a 1-hour interval is the boundary - should be valid
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 60, intervalHours: 1, schedule: .allDayEveryDay)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.policyMessage)
    }

    func testHourlyRejectsZeroInterval() {
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 30, intervalHours: 0, schedule: .allDayEveryDay)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }

    // MARK: - Daily max allowance

    func testDailyRejectsAllowanceExceedingFullDay() {
        let result = RuleValidation.validate(mode: .daily, allowedMinutes: 1441, intervalHours: 1, schedule: .allDayEveryDay)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }

    func testDailyMaxAllowanceIs1440() {
        let result = RuleValidation.validate(mode: .daily, allowedMinutes: 1440, intervalHours: 1, schedule: .allDayEveryDay)
        XCTAssertEqual(result.maxAllowanceMinutes, 1440)
    }

    // MARK: - intervalHours clamping reflected in maxAllowance

    func testIntervalHoursClampedToOneWhenZero() {
        // intervalHours <= 0 clamps to 1 for max calculation, so max = 60
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 30, intervalHours: 0, schedule: .allDayEveryDay)
        XCTAssertEqual(result.maxAllowanceMinutes, 60)
    }

    func testIntervalHoursClampedTo24WhenOver() {
        // intervalHours > 24 clamps to 24, so max = 1440
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 60, intervalHours: 25, schedule: .allDayEveryDay)
        XCTAssertEqual(result.maxAllowanceMinutes, 1440)
    }

    func testMaxAllowanceUpdatesWithInterval() {
        // Increasing interval hours should increase maxAllowanceMinutes
        let result2h = RuleValidation.validate(mode: .hourly, allowedMinutes: 1, intervalHours: 2, schedule: .allDayEveryDay)
        let result4h = RuleValidation.validate(mode: .hourly, allowedMinutes: 1, intervalHours: 4, schedule: .allDayEveryDay)
        XCTAssertEqual(result2h.maxAllowanceMinutes, 120)
        XCTAssertEqual(result4h.maxAllowanceMinutes, 240)
    }

    // MARK: - Scheduled window

    func testScheduledWindowRejectsEqualStartAndEndTime() {
        let schedule = RuleSchedule(activeDays: Set(1...7), startHour: 9, startMinute: 0, endHour: 9, endMinute: 0)
        let result = RuleValidation.validate(mode: .scheduledWindow, allowedMinutes: 0, intervalHours: 1, schedule: schedule)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.scheduleMessage)
    }

    func testScheduledWindowRejectsEmptyActiveDays() {
        let schedule = RuleSchedule(activeDays: [], startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)
        let result = RuleValidation.validate(mode: .scheduledWindow, allowedMinutes: 30, intervalHours: 1, schedule: schedule)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.scheduleMessage)
    }

    func testScheduledWindowMaxAllowanceMatchesWindowDuration() {
        // 9:00-17:00 = 480 minutes
        let schedule = RuleSchedule(activeDays: Set(1...7), startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)
        let result = RuleValidation.validate(mode: .scheduledWindow, allowedMinutes: 60, intervalHours: 1, schedule: schedule)
        XCTAssertEqual(result.maxAllowanceMinutes, 480)
    }

    func testScheduledWindowRejectsAllowanceExceedingWindow() {
        // 9:00-10:00 = 60 min window, 90 min allowance is too large
        let schedule = RuleSchedule(activeDays: Set(1...7), startHour: 9, startMinute: 0, endHour: 10, endMinute: 0)
        let result = RuleValidation.validate(mode: .scheduledWindow, allowedMinutes: 90, intervalHours: 1, schedule: schedule)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }

    // MARK: - intervalHours edit-flow preservation

    func testIntervalHoursPreservedWhenAllowanceFits() {
        // intervalHours: 3 -> max 180 min; allowance 120 fits - valid
        let result = RuleValidation.validate(mode: .hourly, allowedMinutes: 120, intervalHours: 3, schedule: .allDayEveryDay)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.maxAllowanceMinutes, 180)
    }

    func testIntervalHoursChangeInvalidatesExistingAllowance() {
        // Was valid with intervalHours:3 (max 180), but after reducing to 1 (max 60), 120 min is too much
        let resultBefore = RuleValidation.validate(mode: .hourly, allowedMinutes: 120, intervalHours: 3, schedule: .allDayEveryDay)
        let resultAfter  = RuleValidation.validate(mode: .hourly, allowedMinutes: 120, intervalHours: 1, schedule: .allDayEveryDay)
        XCTAssertTrue(resultBefore.isValid)
        XCTAssertFalse(resultAfter.isValid)
    }

    // MARK: - Negative allowance

    func testRejectsNegativeAllowance() {
        let result = RuleValidation.validate(mode: .daily, allowedMinutes: -1, intervalHours: 1, schedule: .allDayEveryDay)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.policyMessage)
    }
}
