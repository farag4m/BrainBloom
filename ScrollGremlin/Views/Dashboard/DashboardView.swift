import SwiftUI

// MARK: - TodayView
//
// GradientBackground sits OUTSIDE NavigationStack in a ZStack so it bleeds
// behind the nav bar, under the tab bar, and through every card's ultraThinMaterial.

struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            NavigationStack {
                Group {
                    if viewModel.rules.isEmpty {
                        EmptyDashboardView(onAddRule: { viewModel.showAddRule = true })
                    } else {
                        let items = viewModel.todayItems
                        if items.isEmpty {
                            NoRulesTodayView()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                                    TodayHero(ruleCount: items.count)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                        .padding(.bottom, 16)

                                    Section {
                                        ForEach(items) { item in
                                            RuleCardView(
                                                item: item,
                                                onToggle: { viewModel.toggleRule(item.rule) },
                                                onUpdate: { viewModel.updateRule($0) },
                                                onDelete: { viewModel.deleteRule(item.rule) }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                        }
                                    } header: {
                                        SectionHeader(title: todayTitle)
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .background(.clear)
                            .refreshable { viewModel.loadData() }
                        }
                    }
                }
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        AddRuleButton(action: { viewModel.showAddRule = true })
                    }
                }
            }
            .background(.clear)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var todayTitle: String {
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - Today Hero
//
// Pastel gradient card (blue → lavender → pink). Text is white.
// Shadow uses lavender tint to match gradient, not teal.

private struct TodayHero: View {
    let ruleCount: Int

    private var subtitle: String {
        switch ruleCount {
        case 0: return "Nothing active today"
        case 1: return "1 rule protecting your time"
        default: return "\(ruleCount) rules protecting your time"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Mascot in glass circle
            ZStack {
                SGMascotFrame(size: 80)
                Image("Gremlin")
                    .resizable().scaledToFit()
                    .frame(width: 58, height: 58)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("SCROLLGREMLIN")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.70))
                    .kerning(1.2)
                Text(formattedDate)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(20)
        .background(SGHeroCardSurface(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color(red: 0.74, green: 0.69, blue: 0.95).opacity(0.30), radius: 22, y: 10)
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    private var formattedDate: String {
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - No Rules Today

private struct NoRulesTodayView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Gremlin")
                .resizable().scaledToFit()
                .frame(width: 72, height: 72).opacity(0.65)
            Text("Nothing scheduled today")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Dashboard View

struct EmptyDashboardView: View {
    let onAddRule: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                GlassCard(cornerRadius: 28)
                VStack(spacing: 14) {
                    Image("Gremlin_Annoyed")
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                    Text("No Rules Yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(28)
            }
            .frame(width: 200, height: 188)

            Text("Add a rule to start managing your app usage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddRule) { Label("Add First Rule", systemImage: "plus") }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 228)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
