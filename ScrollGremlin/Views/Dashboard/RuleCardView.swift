import SwiftUI
import Combine

struct RuleCardView: View {
    let item: RuleDisplayItem
    let onToggle: () -> Void
    let onUpdate: (AppRule) -> Void
    let onDelete: () -> Void

    @State private var showDetail = false
    @State private var activeSession: UnlockSession? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.rule.name)
                        .font(.headline)
                    Text(item.rule.policy.displayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadgeView(badge: item.badge)

                Toggle("", isOn: Binding(
                    get: { item.rule.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }

            remainingRow
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Rule", systemImage: "trash")
            }
        }
        .onTapGesture { showDetail = true }
        .onAppear { refreshSession() }
        .onReceive(
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification)
                .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
        ) { _ in refreshSession() }
        .sheet(isPresented: $showDetail) {
            RuleDetailView(rule: item.rule, status: item.badge, onUpdate: onUpdate, onDelete: onDelete)
        }
    }

    @ViewBuilder
    private var remainingRow: some View {
        switch item.badge {
        case .disabled:
            EmptyView()
        case .offToday:
            timeRow(icon: "clock", text: "Not active today")
        case .locked:
            timeRow(icon: "lock.fill", text: "00:00:00 remaining")
        case .active:
            if let session = activeSession {
                if let expiresAt = session.expiresAt {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let secs = max(0, Int(expiresAt.timeIntervalSinceNow))
                        timeRow(icon: "clock", text: "\(formatHHMMSS(secs)) remaining")
                    }
                } else {
                    timeRow(icon: "clock", text: "Unlocked for today")
                }
            } else {
                timeRow(icon: "clock", text: "\(formatHHMMSS(item.rule.policy.allowedMinutes * 60)) remaining")
            }
        }
    }

    private func timeRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshSession() {
        activeSession = AppGroupStore.shared.loadUnlockSessions()
            .filter {
                $0.ruleID == item.rule.id &&
                Calendar.current.isDateInToday($0.startedAt) &&
                $0.actualEndedAt == nil
            }
            .sorted { $0.startedAt > $1.startedAt }
            .first
    }

    private func formatHHMMSS(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - RuleDetailView

struct RuleDetailView: View {
    let rule: AppRule
    let onUpdate: (AppRule) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var unlockSessions: [UnlockSession] = []
    @State private var liveStatus: RuleStatusBadge

    init(rule: AppRule, status: RuleStatusBadge, onUpdate: @escaping (AppRule) -> Void, onDelete: @escaping () -> Void) {
        self.rule = rule
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._liveStatus = State(initialValue: status)
    }

    private func computeStatus() -> RuleStatusBadge {
        if !rule.isEnabled { return .disabled }
        if AppGroupStore.shared.isShielded(rule.id) { return .locked }
        if !rule.schedule.isActiveNow { return .offToday }
        return .active
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Rule Info") {
                    LabeledContent("Allowance") {
                        Text(rule.policy.displayLabel)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Status") {
                        StatusBadgeView(badge: liveStatus)
                    }
                }

                if !unlockSessions.isEmpty {
                    Section("Today's Unlocks") {
                        ForEach(unlockSessions) { session in
                            UnlockSessionRow(session: session)
                        }
                    }
                }

                Section {
                    Button("Edit Rule") { showEdit = true }
                    Button("Delete Rule", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .navigationTitle(rule.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            RuleEditorView(rule: rule, onDelete: {
                onDelete()
                dismiss()
            }, onSave: { updatedRule in
                onUpdate(updatedRule)
                dismiss()
            })
        }
        .onAppear {
            liveStatus = computeStatus()
            unlockSessions = AppGroupStore.shared.loadUnlockSessions()
                .filter {
                    $0.ruleID == rule.id &&
                    Calendar.current.isDateInToday($0.startedAt)
                }
                .sorted { $0.startedAt > $1.startedAt }
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification)
                .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
        ) { _ in
            liveStatus = computeStatus()
        }
    }
}

// MARK: - UnlockSessionRow

struct UnlockSessionRow: View {
    let session: UnlockSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.startedAt, style: .time)
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(session.unlockType.displayLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let intention = session.intention, !intention.isEmpty {
                Text(intention)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
