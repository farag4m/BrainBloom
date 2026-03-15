import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var ruleManager: RuleManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingFlow()
            } else if authManager.status == .authorized {
                MainTabView()
            } else {
                PermissionView()
            }
        }
        .animation(.easeInOut, value: authManager.status)
        .fullScreenCover(isPresented: $ruleManager.showUnlockFlow) {
            if let ruleID = ruleManager.unlockRuleID {
                UnlockFlowView(ruleID: ruleID)
            }
        }
    }
}

struct MainTabView: View {
    // Single DashboardViewModel shared by both dashboard tabs.
    // @StateObject creates it once for the lifetime of MainTabView.
    // Both tabs observe the same object — a toggle in one tab instantly
    // reflects in the other with no extra wiring.
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        TabView {
            TodayView(viewModel: viewModel)
                .tabItem { Label("Today", systemImage: "shield.fill") }

            AllRulesView(viewModel: viewModel)
                .tabItem { Label("Rules", systemImage: "list.bullet") }

            HistoryView()
                .tabItem { Label("History", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        // Tab bar — frosted glass surface matching the design system
        .tint(Color.sgTeal)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        // Sheets live here so they work from either tab without duplication.
        .sheet(isPresented: $viewModel.showAddRule) {
            AddRuleView { rule in
                viewModel.addRule(rule)
            }
        }
    }
}

struct PermissionView: View {
    @EnvironmentObject var authManager: AuthorizationManager

    var body: some View {
        OnboardingPermissionView(onAuthorized: {
            // AuthorizationManager.status updates automatically
        })
        .environmentObject(authManager)
    }
}
