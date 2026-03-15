import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No History Yet")
                            .font(.headline)
                        Text("Your unlock history will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        HStack(spacing: 24) {
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
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

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
            .navigationTitle("History")
            .refreshable { viewModel.loadData() }
        }
        .onAppear { viewModel.loadData() }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.intentBlockPrimary)
            Text(value)
                .font(.title2).fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct HistorySessionRow: View {
    let session: UnlockSession
    let ruleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(ruleName)
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(session.unlockType.displayLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.intentBlockPrimary.opacity(0.15))
                    .foregroundStyle(Color.intentBlockPrimary)
                    .clipShape(Capsule())
            }

            HStack {
                Text(session.startedAt, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
                if let intention = session.intention, !intention.isEmpty {
                    Text("·")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(intention)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
