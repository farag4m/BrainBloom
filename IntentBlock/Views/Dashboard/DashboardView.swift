import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                let items = viewModel.todayItems

                if viewModel.rules.isEmpty {
                    EmptyDashboardView(onAddRule: { viewModel.showAddRule = true })
                } else if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No rules scheduled for today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                            Section {
                                ForEach(items) { item in
                                    RuleCardView(
                                        item: item,
                                        onToggle: { viewModel.toggleRule(item.rule) },
                                        onUpdate: { viewModel.updateRule($0) },
                                        onDelete: { viewModel.deleteRule(item.rule) }
                                    )
                                }
                            } header: {
                                SectionHeader(title: todayTitle)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .refreshable { viewModel.loadData() }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showAddRule = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var todayTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - Shared helpers

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .background(Color(UIColor.systemGroupedBackground))
    }
}

struct EmptyDashboardView: View {
    let onAddRule: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Rules Yet")
                    .font(.title3).fontWeight(.semibold)
                Text("Add a rule to start managing your app usage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddRule) {
                Label("Add First Rule", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.intentBlockPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
    }
}
