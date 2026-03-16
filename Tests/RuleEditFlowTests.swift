import Foundation
import XCTest
@testable import BrainBloom

// Tests that cover the edit-flow persistence path at the model layer.
//
// RuleEditorViewModel tests are intentionally excluded: the VM holds a
// FamilyActivitySelection property (FamilyControls) which cannot be
// instantiated in the test host — it requires a live ScreenTime authorization
// session that is only available in production. Those tests must run on device.

final class RuleEditFlowTests: XCTestCase {

    // MARK: - UsagePolicy JSON roundtrip

    func testUsagePolicyRecurringRoundtrips() throws {
        let original = UsagePolicy.recurring(minutes: 20, everyHours: 3)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsagePolicy.self, from: data)
        XCTAssertEqual(decoded.type, .recurringInterval)
        XCTAssertEqual(decoded.allowedMinutes, 20)
        XCTAssertEqual(decoded.intervalHours, 3)
    }

    func testUsagePolicyDailyRoundtrips() throws {
        let original = UsagePolicy.daily(minutes: 90)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsagePolicy.self, from: data)
        XCTAssertEqual(decoded.type, .daily)
        XCTAssertEqual(decoded.allowedMinutes, 90)
        XCTAssertEqual(decoded.intervalHours, 24)
    }

    // MARK: - AppRule JSON roundtrip
    // AppRule is built via AppRuleFixture → JSON → AppRule to avoid calling
    // JSONEncoder.encode(FamilyActivitySelection), which crashes without a live
    // ScreenTime session. selectionData is set to Data() (empty); rule.selection
    // will return nil, which is fine for these model-layer tests.

    func testAppRuleRecurringPolicyRoundtripsViaJSON() throws {
        let rule = makeRule(name: "Gaming", policy: .recurring(minutes: 45, everyHours: 2))
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(AppRule.self, from: data)
        XCTAssertEqual(decoded.name, "Gaming")
        XCTAssertEqual(decoded.policy.type, .recurringInterval)
        XCTAssertEqual(decoded.policy.allowedMinutes, 45)
        XCTAssertEqual(decoded.policy.intervalHours, 2)
    }

    func testAppRuleIDIsPreservedAcrossJSON() throws {
        let id = UUID()
        let rule = makeRule(id: id, name: "Test", policy: .daily(minutes: 30))
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(AppRule.self, from: data)
        XCTAssertEqual(decoded.id, id)
    }
}

// MARK: - Fixture helpers

private struct AppRuleFixture: Codable {
    let id: UUID
    let name: String
    let selectionData: Data
    let policy: UsagePolicy
    let isEnabled: Bool
    let schedule: RuleSchedule
    let frictionOverride: FrictionType?
    let unlockDurationOverride: UnlockType?
    let createdAt: Date
    let updatedAt: Date
}

private func makeRule(
    id: UUID = UUID(),
    name: String,
    policy: UsagePolicy,
    schedule: RuleSchedule = .allDayEveryDay
) -> AppRule {
    let fixture = AppRuleFixture(
        id: id,
        name: name,
        selectionData: Data(),
        policy: policy,
        isEnabled: true,
        schedule: schedule,
        frictionOverride: nil,
        unlockDurationOverride: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    do {
        let data = try JSONEncoder().encode(fixture)
        return try JSONDecoder().decode(AppRule.self, from: data)
    } catch {
        fatalError("Failed to build AppRule fixture: \(error)")
    }
}
