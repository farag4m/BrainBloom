import Foundation
import XCTest
@testable import BrainBloom

final class UnlockSessionQueriesTests: XCTestCase {
    func testActiveSessionIgnoresEndedSessions() {
        let ruleID = UUID()
        let session = makeSession(ruleID: ruleID, startedAt: Date(), actualEndedAt: Date())
        let active = UnlockSessionQueries.activeSession(for: ruleID, in: [session], now: Date())
        XCTAssertNil(active)
    }

    func testActiveSessionReturnsMostRecentToday() {
        let ruleID = UUID()
        let session1 = makeSession(ruleID: ruleID, startedAt: Date().addingTimeInterval(-300), actualEndedAt: nil)
        let session2 = makeSession(ruleID: ruleID, startedAt: Date().addingTimeInterval(-60), actualEndedAt: nil)
        let active = UnlockSessionQueries.activeSession(for: ruleID, in: [session1, session2], now: Date())
        XCTAssertEqual(active?.startedAt, session2.startedAt)
    }

    private func makeSession(ruleID: UUID, startedAt: Date, actualEndedAt: Date?) -> UnlockSession {
        let fixture = UnlockSessionFixture(
            id: UUID(),
            ruleID: ruleID,
            startedAt: startedAt,
            expiresAt: nil,
            actualEndedAt: actualEndedAt,
            unlockType: .fiveMinutes,
            intention: nil,
            frictionType: .none,
            wasEndedManually: false
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        do {
            let data = try encoder.encode(fixture)
            return try decoder.decode(UnlockSession.self, from: data)
        } catch {
            fatalError("Failed to build UnlockSession fixture: \(error)")
        }
    }
}

private struct UnlockSessionFixture: Codable {
    let id: UUID
    let ruleID: UUID
    let startedAt: Date
    let expiresAt: Date?
    let actualEndedAt: Date?
    let unlockType: UnlockType
    let intention: String?
    let frictionType: FrictionType
    let wasEndedManually: Bool
}
