import SwiftUI

struct AllRulesView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardGridBackground().ignoresSafeArea()

                ScrollView {
                    if viewModel.rules.isEmpty {
                        EmptyRulesState(onAddRule: { viewModel.showAddRule = true })
                            .padding(.top, 12)
                    } else {
                        let groups = viewModel.allRulesDayGroups
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
                }
                .background(.clear)
                .refreshable { viewModel.loadData() }
            }
            .navigationTitle("All Rules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddRuleButton(action: { viewModel.showAddRule = true })
                }
            }
            .background(.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
