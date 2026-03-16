import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            NavigationStack {
                List {
                    Section {
                        HStack(spacing: 14) {
                            StatCard(
                                value: "\(viewModel.totalUnlocksThisWeek)",
                                label: "Unlocks this week",
                                icon: "lock.open"
                            )
                            if viewModel.settings.showStreakCounter {
                                StatCard(
                                    value: "\(viewModel.currentStreak)",
                                    label: "Low-screen-time streak",
                                    icon: "flame"
                                )
                            }
                        }
                        .padding(.vertical, 2)
                        if viewModel.settings.showStreakCounter {
                            Text(viewModel.streakDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if viewModel.sessions.isEmpty {
                        EmptyHistoryView()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.sessionsGroupedByDate, id: \.0) { (date, sessions) in
                            Section(header: Text(date, style: .date)) {
                                ForEach(sessions) { session in
                                    HistorySessionRow(
                                        session: session,
                                        ruleName: viewModel.ruleName(for: session)
                                    )
                                    .listRowBackground(
                                        GlassCard(cornerRadius: 16)
                                            .padding(.vertical, 2)
                                            .padding(.horizontal, 4)
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .refreshable { viewModel.loadData() }
                .navigationTitle("History")
            }
            .background(.clear)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { viewModel.loadData() }
    }
}

// MARK: - Empty History

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 14) {
            GlassLeafIcon(size: 72, tint: Color.sgTeal.opacity(0.85), glassTint: Color.sgTeal.opacity(0.35))
            Text("No history yet")
                .font(.headline)
            Text("Your unlocks will show up here as you go.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.sgTeal.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(Color.sgTeal)
            }
            Text(value)
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background {
            GlassCard(cornerRadius: 24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - History Session Row

private struct HistorySessionRow: View {
    let session: UnlockSession
    let ruleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(ruleName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(session.unlockType.displayLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.sgTeal.opacity(0.35), lineWidth: 1))
                    .foregroundStyle(Color.sgTeal)
                    .clipShape(Capsule())
            }

            HStack {
                Text(session.startedAt, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
                if let intention = session.intention, !intention.isEmpty {
                    Text("·").font(.caption).foregroundStyle(.secondary)
                    Text(intention)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
