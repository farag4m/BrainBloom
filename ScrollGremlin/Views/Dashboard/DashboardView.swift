import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.rules.isEmpty {
                    EmptyDashboardView(onAddRule: { viewModel.showAddRule = true })
                        .sgSurfaceBackground()
                } else {
                    ZStack(alignment: .top) {
                        SGAmbientBackground()
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
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }
}

// MARK: - Today Hero
//
// Aurora gradient card with a glass-coin-framed mascot on the left.
// All text is white against the vivid gradient surface.

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
            // Mascot in glass coin — feels part of the gradient surface
            ZStack {
                SGMascotFrame(size: 80)
                Image("Gremlin")
                    .resizable().scaledToFit()
                    .frame(width: 64, height: 64)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("SCROLLGREMLIN")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .kerning(1.2)
                Text(formattedDate)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()
        }
        .padding(20)
        .background(SGHeroCardSurface(cornerRadius: 24))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.sgTeal.opacity(0.24), radius: 22, y: 9)
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
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
    }
}

// MARK: - Section Header
//
// Frosted glass sticky header — content scrolls through, label stays readable.

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
    }
}

// MARK: - Empty Dashboard View
//
// Mascot lives inside a premium GlassCard — not pasted on a plain background.

struct EmptyDashboardView: View {
    let onAddRule: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 32) {
            // Mascot card
            ZStack {
                GlassCard(cornerRadius: 28)
                VStack(spacing: 14) {
                    Image("Gremlin_Annoyed")
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                    Text("No Rules Yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(scheme == .dark ? .white : Color(red: 0.10, green: 0.22, blue: 0.18))
                }
                .padding(28)
            }
            .frame(width: 200, height: 188)
            // Top-edge highlight
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(scheme == .dark ? 0.18 : 0.88), .white.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.sgTeal.opacity(scheme == .dark ? 0.0 : 0.10), radius: 22, y: 9)
            .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.07), radius: 14, y: 5)

            VStack(spacing: 8) {
                Text("Add a rule to start managing your app usage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddRule) { Label("Add First Rule", systemImage: "plus") }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 228)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
