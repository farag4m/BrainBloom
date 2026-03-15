import SwiftUI
import Combine

struct RuleCardView: View {
    let item: RuleDisplayItem
    let onToggle: () -> Void
    let onUpdate: (AppRule) -> Void
    let onDelete: () -> Void

    @State private var showDetail = false
    @State private var activeSession: UnlockSession? = nil
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Left accent strip for active rules
                if item.badge == .active {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.sgTeal)
                        .frame(width: 3)
                        .padding(.vertical, 2)
                }

                VStack(alignment: .leading, spacing: 3) {
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
                .tint(Color.sgTeal)
            }

            remainingRow
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: item.badge == .active ? Color.sgTeal.opacity(0.08) : .clear, radius: 8, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    item.badge == .locked ? Color.sgTeal.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Rule", systemImage: "trash")
            }
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            showDetail = true
        }
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
            timeRow(icon: "moon.zzz", text: "Not active today")
        case .locked:
            HStack(spacing: 6) {
                Image("Gremlin_Annoyed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("Blocked — limit reached")
                    .font(.caption)
                    .foregroundStyle(Color.sgTeal)
                    .fontWeight(.medium)
            }
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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.sgTeal.opacity(0.7))
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
                // Annoyed gremlin when blocked
                if liveStatus == .locked {
                    Section {
                        HStack(spacing: 14) {
                            Image("Gremlin_Annoyed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Limit reached")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Color.sgTeal)
                                Text("Your allowance is used up for this window.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.sgTeal.opacity(0.06))
                }

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
