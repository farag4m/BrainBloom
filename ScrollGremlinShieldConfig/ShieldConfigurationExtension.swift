import ManagedSettingsUI
import ManagedSettings
import UIKit

class ScrollGremlinShieldConfiguration: ShieldConfigurationDataSource {

    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        makeConfiguration(subtitle: "You've used your allowance for this app.")
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration(subtitle: "You've used your allowance for this category.")
    }

    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        makeConfiguration(subtitle: "You've used your allowance for this site.")
    }

    private func makeConfiguration(subtitle: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 0.95),
            title: ShieldConfiguration.Label(
                text: "Time's Up",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.white.withAlphaComponent(0.75)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock Intentionally",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white.withAlphaComponent(0.6)
            )
        )
    }
}
