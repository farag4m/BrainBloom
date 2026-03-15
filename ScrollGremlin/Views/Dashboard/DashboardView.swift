import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.rules.isEmpty {
                    EmptyDashboardView(onAddRule: { viewModel.showAddRule = true })
                        .sgPageBackground()
                } else {
                    let items = viewModel.todayItems
                    ZStack(alignment: .top) {
                        // Gradient page background
                        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                        SGGradient.pageTint
                            .frame(maxWidth: .infinity, maxHeight: 420)
                            .ignoresSafeArea(edges: .top)
                            .allowsHitTesting(false)

                        if items.isEmpty {
                            NoRulesTodayView()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                                    // Hero header
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
                                            .padding(.bottom, 10)
                                        }
                                    } header: {
                                        SectionHeader(title: todayTitle)
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                            .refreshable { viewModel.loadData() }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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

    private var todayTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - Today Hero

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
            ZStack {
                SGMascotGlow(size: 90)
                Image("Gremlin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.sgTeal.opacity(0.35), radius: 12, y: 4)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("SCROLLGREMLIN")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.sgTeal)
                    .kerning(1.2)

                Text(formattedDate)
                    .font(.title3.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 22)
                    .fill(SGGradient.hero)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.sgTeal.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: Color.sgTeal.opacity(0.14), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - No Rules Today

private struct NoRulesTodayView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Gremlin")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .opacity(0.65)
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
            .padding(.vertical, 6)
            .background(Color(UIColor.systemGroupedBackground).opacity(0.92))
    }
}

struct EmptyDashboardView: View {
    let onAddRule: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // Mascot in a glowing frame
            ZStack {
                SGMascotGlow(size: 160)
                Circle()
                    .stroke(Color.sgTeal.opacity(0.18), lineWidth: 1)
                    .frame(width: 148, height: 148)
                Image("Gremlin_Annoyed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
            }

            VStack(spacing: 8) {
                Text("No Rules Yet")
                    .font(.title3.weight(.semibold))
                Text("Add a rule to start managing your app usage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddRule) {
                Label("Add First Rule", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 220)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
