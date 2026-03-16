import ManagedSettings
import Foundation

class BrainBloomShieldAction: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            handleUnlockRequest(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            handleUnlockRequest(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            handleUnlockRequest(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func handleUnlockRequest(completionHandler: @escaping (ShieldActionResponse) -> Void) {
        let groupStore = AppGroupStore.shared
        let shieldState = groupStore.allShieldStates()
        let shieldedRuleIDs = shieldState
            .filter { $0.value }
            .compactMap { UUID(uuidString: $0.key) }

        if let ruleID = shieldedRuleIDs.first {
            let request = UnlockRequest(ruleID: ruleID)
            groupStore.setPendingUnlockRequest(request)
        }

        // The pending unlock request is now in AppGroup; the main app will
        // pick it up when the user opens it via the .defer response.
        completionHandler(.close)
    }
}
