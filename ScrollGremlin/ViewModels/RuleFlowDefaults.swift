import Foundation

struct RuleFlowDefaults {
    let defaultUnlockType: UnlockType
    let defaultFriction: FrictionType

    static func current() -> RuleFlowDefaults {
        let settings = AppGroupStore.shared.loadSettings()
        return RuleFlowDefaults(
            defaultUnlockType: settings.defaultUnlockType,
            defaultFriction: settings.defaultFriction
        )
    }
}
