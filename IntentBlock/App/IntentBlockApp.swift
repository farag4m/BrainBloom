import SwiftUI
import FamilyControls
import Combine

@main
struct IntentBlockApp: App {
    @StateObject private var authManager = AuthorizationManager.shared
    @StateObject private var ruleManager = RuleManager.shared
    @StateObject private var appearanceManager = AppearanceManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(ruleManager)
                .preferredColorScheme(appearanceManager.preferredColorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "intentblock" else { return }
        if url.host == "unlock" {
            ruleManager.handlePendingUnlockRequest()
        }
    }
}

// MARK: - AppearanceManager

@MainActor
private final class AppearanceManager: ObservableObject {
    @Published var preferredColorScheme: ColorScheme? = nil
    private var cancellable: AnyCancellable?

    init() {
        refresh()
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        preferredColorScheme = AppGroupStore.shared.loadSettings().colorScheme.swiftUIColorScheme
    }
}
