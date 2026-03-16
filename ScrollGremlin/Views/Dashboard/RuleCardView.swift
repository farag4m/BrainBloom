import SwiftUI
import Combine

// MARK: - Animated Rule Card (STEP 5 & 8)
//
// Card uses GlassCard (ultraThinMaterial) — no teal/green fill.
// Active state animates: border color, shadow intensity, badge color.
// All animations use .spring(response: 0.4, dampingFraction: 0.8).

struct RuleCardView: View {
    let item: RuleDisplayItem
    let onToggle: () -> Void
    let onUpdate: (AppRule) -> Void
    let onDelete: () -> Void

    @State private var showDetail = false
    @State private var isPressed = false

    private var isActive: Bool { item.badge == .active }
    private var isLocked: Bool { item.badge == .locked }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ── Top row ──────────────────────────────────────────────────────
            HStack(spacing: 12) {
                // Accent strip — teal brand gradient, fades in when active
                RoundedRectangle(cornerRadius: 2)
                    .fill(AnyShapeStyle(SGGradient.brand))
                    .frame(width: 3, height: 36)
                    .opacity(isActive ? 1.0 : 0.0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.rule.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
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

            // ── Status row ───────────────────────────────────────────────────
            Group { statusRow }
                .id(item.badge)
                .transition(.opacity.animation(.easeInOut(duration: 0.22)))
        }
        .padding(18)
        // GlassCard surface with animated active border (STEP 5 & 8)
        .sgCard(active: isActive, locked: isLocked)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        // Animate background, shadow, badge, accent strip on state change
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: item.badge)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLocked)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Rule", systemImage: "trash")
            }
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { isPressed = false }
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            RuleDetailView(rule: item.rule, status: item.badge, onUpdate: onUpdate, onDelete: onDelete)
        }
    }

    // MARK: Status row

    @ViewBuilder
    private var statusRow: some View {
        switch item.badge {
        case .disabled:
            EmptyView()
        case .offToday:
            infoRow(icon: "moon.zzz", text: "Not active today")
        case .locked:
            HStack(spacing: 8) {
                Image("Gremlin_Annoyed")
                    .resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                Text("Blocked — limit reached")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.82))
            }
        case .active:
            if let session = item.activeSession {
                if let expiresAt = session.expiresAt {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let secs = max(0, Int(expiresAt.timeIntervalSinceNow))
                        infoRow(icon: "clock", text: "\(formatHHMMSS(secs)) remaining")
                    }
                } else {
                    infoRow(icon: "clock", text: "Unlocked for today")
                }
            } else {
                infoRow(icon: "clock", text: "\(formatHHMMSS(item.rule.policy.allowedMinutes * 60)) remaining")
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.sgTeal.opacity(0.75))
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatHHMMSS(_ seconds: Int) -> String {
        String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
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

    init(rule: AppRule, status: RuleStatusBadge,
         onUpdate: @escaping (AppRule) -> Void,
         onDelete: @escaping () -> Void) {
        self.rule = rule; self.onUpdate = onUpdate; self.onDelete = onDelete
        self._liveStatus = State(initialValue: status)
    }

    private func computeStatus() -> RuleStatusBadge {
        RuleStatusBadge.make(for: rule, isShielded: AppGroupStore.shared.isShielded(rule.id))
    }

    private func refreshDetailData() {
        liveStatus = computeStatus()
        unlockSessions = UnlockSessionQueries.todaySessions(for: rule.id, in: AppGroupStore.shared.loadUnlockSessions())
    }

    var body: some View {
        NavigationStack {
            List {
                if liveStatus == .locked {
                    Section {
                        HStack(spacing: 14) {
                            Image("Gremlin_Annoyed")
                                .resizable().scaledToFit().frame(width: 48, height: 48)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Limit reached")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.sgTeal)
                                Text("Your allowance is used up for this window.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.sgTeal.opacity(0.07))
                }

                Section("Rule Info") {
                    LabeledContent("Allowance") {
                        Text(rule.policy.displayLabel).foregroundStyle(.secondary)
                    }
                    LabeledContent("Status") { StatusBadgeView(badge: liveStatus) }
                }

                if !unlockSessions.isEmpty {
                    Section("Today's Unlocks") {
                        ForEach(unlockSessions) { UnlockSessionRow(session: $0) }
                    }
                }

                Section {
                    Button("Edit Rule") { showEdit = true }
                    Button("Delete Rule", role: .destructive) { onDelete(); dismiss() }
                }
            }
            .navigationTitle(rule.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
        .sheet(isPresented: $showEdit) {
            RuleEditorView(rule: rule, onDelete: { onDelete(); dismiss() }, onSave: { updatedRule in
                onUpdate(updatedRule); dismiss()
            })
        }
        .onAppear { refreshDetailData() }
        .onReceive(
            NotificationCenter.default
                .publisher(for: UserDefaults.didChangeNotification)
                .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
        ) { _ in refreshDetailData() }
    }
}

// MARK: - UnlockSessionRow

struct UnlockSessionRow: View {
    let session: UnlockSession
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.startedAt, style: .time).font(.subheadline.weight(.medium))
                Spacer()
                Text(session.unlockType.displayLabel).font(.caption).foregroundStyle(.secondary)
            }
            if let intention = session.intention, !intention.isEmpty {
                Text(intention).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
