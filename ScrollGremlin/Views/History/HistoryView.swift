import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                SGGradient.pageTint
                    .frame(maxWidth: .infinity, maxHeight: 380)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)

                List {
                    if viewModel.sessions.isEmpty {
                        EmptyHistoryView()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        // Stat cards
                        Section {
                            HStack(spacing: 14) {
                                StatCard(
                                    value: "\(viewModel.totalUnlocksThisWeek)",
                                    label: "Unlocks this week",
                                    icon: "lock.open"
                                )
                                StatCard(
                                    value: "\(viewModel.currentStreak)",
                                    label: "Day streak",
                                    icon: "flame"
                                )
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                        ForEach(viewModel.sessionsGroupedByDate, id: \.0) { (date, sessions) in
                            Section(header: Text(date, style: .date)) {
                                ForEach(sessions) { session in
                                    HistorySessionRow(
                                        session: session,
                                        ruleName: viewModel.ruleName(for: session)
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable { viewModel.loadData() }
            }
            .navigationTitle("History")
        }
        .onAppear { viewModel.loadData() }
    }
}

// MARK: - Empty History

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Gremlin")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .opacity(0.65)
            Text("No History Yet")
                .font(.headline)
            Text("Your unlock history will appear here.")
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
    @Environment(\.colorScheme) private var scheme

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
        .sgCard()
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
                    .background(Color.sgTeal.opacity(0.12))
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
