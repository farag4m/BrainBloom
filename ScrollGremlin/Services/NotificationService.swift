import UserNotifications
import Foundation

public final class NotificationService {
    public static let shared = NotificationService()
    private init() {}

    public func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    public func scheduleWarningNotification(for rule: AppRule) {
        let content = UNMutableNotificationContent()
        content.title = "Almost at your limit"
        content.body = "You're close to your screen time allowance for \"\(rule.name)\"."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "scrollgremlin.warning.\(rule.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    public func scheduleLockedNotification(for rule: AppRule) {
        let content = UNMutableNotificationContent()
        content.title = "Time's up"
        content.body = "You've used your allowance for \"\(rule.name)\". Open ScrollGremlin to continue."
        content.sound = .default
        content.userInfo = ["ruleID": rule.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "scrollgremlin.locked.\(rule.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    public func scheduleGraceEndedNotification(for rule: AppRule) {
        let content = UNMutableNotificationContent()
        content.title = "Unlock ended"
        content.body = "Your extra time for \"\(rule.name)\" is up. The app is blocked again."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "scrollgremlin.grace_ended.\(rule.id).\(UUID())",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    public func cancelAllNotifications(for ruleID: UUID) {
        let identifiers = [
            "scrollgremlin.warning.\(ruleID)",
            "scrollgremlin.locked.\(ruleID)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
