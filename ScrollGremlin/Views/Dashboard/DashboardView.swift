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
                    NoRulesTodayView()
                } else {
                    ScrollView {
                        // Brand header
                        GremlinHeader()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showAddRule = true }) {
                        Image(systemName: "plus")
                    }
                    .tint(Color.sgTeal)
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

// MARK: - Brand Header

private struct GremlinHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("Gremlin")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text("ScrollGremlin")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(Color.sgTeal)
                Text("Watching your limits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.sgTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.sgTeal.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - No Rules Today

private struct NoRulesTodayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("Gremlin")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .opacity(0.7)
            Text("Nothing scheduled today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
            Image("Gremlin_Annoyed")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

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
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.sgTeal)
                    .foregroundStyle(Color.sgBackground)
                    .clipShape(Capsule())
                    .shadow(color: Color.sgTeal.opacity(0.35), radius: 8, y: 3)
            }
        }
        .padding(32)
    }
}
