import SwiftUI

struct AllRulesView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.rules.isEmpty {
                    EmptyDashboardView(onAddRule: { viewModel.showAddRule = true })
                        .sgPageBackground()
                } else {
                    ZStack(alignment: .top) {
                        SGAmbientBackground()

                        let groups = viewModel.allRulesDayGroups
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                                ForEach(groups) { group in
                                    Section {
                                        ForEach(group.items) { item in
                                            RuleCardView(
                                                item: item,
                                                onToggle: { viewModel.toggleRule(item.rule) },
                                                onUpdate: { viewModel.updateRule($0) },
                                                onDelete: { viewModel.deleteRule(item.rule) }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 10)
                                        }
                                    } header: {
                                        SectionHeader(title: group.title)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .refreshable { viewModel.loadData() }
                    }
                }
            }
            .navigationTitle("All Rules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showAddRule = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.sgTeal)
                            .font(.title3)
                    }
                }
            }
        }
    }
}
