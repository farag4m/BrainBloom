import SwiftUI
import FamilyControls

// MARK: - AddRuleView

/// Entry point for creating a new rule. Uses a NavigationStack with three possible paths:
///   Presets → Rule Details (fast path)
///   Presets → Custom Builder → Rule Details (power-user path)
struct AddRuleView: View {
    let onSave: (AppRule) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var navPath = NavigationPath()
    @State private var showWorkEditor = false

    var body: some View {
        NavigationStack(path: $navPath) {
            PresetsScreen(
                onNavigate: { destination in navPath.append(destination) },
                onWorkPreset: { showWorkEditor = true }
            )
            .navigationDestination(for: AddRuleDest.self) { destination in
                switch destination {
                case .custom:
                    CustomBuilderScreen { policy in
                        navPath.append(AddRuleDest.setup(policy))
                    }
                case .setup(let policy):
                    RuleSetupScreen(policy: policy) { rule in
                        onSave(rule)
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .background(.clear)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showWorkEditor) {
            RuleEditorView(templateSchedule: .workDays) { rule in
                onSave(rule)
                dismiss()
            }
        }
    }
}

// MARK: - Navigation destination

enum AddRuleDest: Hashable {
    case custom
    case setup(UsagePolicy)
}

// MARK: - Presets Screen

private struct PresetsScreen: View {
    let onNavigate: (AddRuleDest) -> Void
    let onWorkPreset: () -> Void

    private let presets: [UsagePolicy] = [
        .daily(minutes: 240),
        .daily(minutes: 120),
        .daily(minutes: 60),
        .daily(minutes: 30),
        .recurring(minutes: 20, everyHours: 1),
        .recurring(minutes: 10, everyHours: 1),
        .recurring(minutes: 10, everyHours: 2),
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Presets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets, id: \.self) { policy in
                            PresetCard(policy: policy) {
                                onNavigate(.setup(policy))
                            }
                        }
                        WorkPresetCard(action: onWorkPreset)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Advanced")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    Button { onNavigate(.custom) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundStyle(Color.scrollGremlinPrimary)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Custom Rule")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Set your own time and interval")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .sgCard(cornerRadius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(.clear)
        .navigationTitle("New Rule")
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let policy: UsagePolicy
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: policy.type == .daily ? "sun.max.fill" : "timer")
                    .font(.title2)
                    .foregroundStyle(Color.scrollGremlinPrimary)
                Spacer(minLength: 4)
                Text(policy.displayLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(minHeight: 100)
            .sgCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Work Preset Card

private struct WorkPresetCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "briefcase.fill")
                    .font(.title2)
                    .foregroundStyle(Color.scrollGremlinPrimary)
                Spacer(minLength: 4)
                Text("Work (9–5)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Mon–Fri schedule")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(minHeight: 100)
            .sgCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Builder Screen

private struct CustomBuilderScreen: View {
    let onContinue: (UsagePolicy) -> Void

    private let allAllowanceOptions: [Int] = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240]
    private let windowOptions: [(label: String, minutes: Int)] = [
        ("every hour",    60),
        ("every 2 hours", 120),
        ("every 3 hours", 180),
        ("every 4 hours", 240),
        ("every 5 hours", 300),
        ("every 6 hours", 360),
        ("daily",         1440),
    ]

    @State private var selectedAllowance: Int = 30
    @State private var selectedWindowMinutes: Int = 1440

    private var validAllowanceOptions: [Int] {
        allAllowanceOptions.filter { $0 < selectedWindowMinutes }
    }

    private var isValid: Bool { selectedAllowance < selectedWindowMinutes }

    private var builtPolicy: UsagePolicy {
        if selectedWindowMinutes == 1440 {
            return .daily(minutes: selectedAllowance)
        }
        return .recurring(minutes: selectedAllowance, everyHours: selectedWindowMinutes / 60)
    }

    var body: some View {
        Form {
            Section {
                Picker("Time allowed", selection: $selectedAllowance) {
                    ForEach(validAllowanceOptions, id: \.self) { m in
                        Text(pickerLabel(m)).tag(m)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("Reset window", selection: $selectedWindowMinutes) {
                    ForEach(windowOptions, id: \.minutes) { opt in
                        Text(opt.label).tag(opt.minutes)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Limit")
            } footer: {
                Text("Apps are blocked once the time allowed is used within each reset window.")
            }

            Section("Preview") {
                LabeledContent("Rule") {
                    Text(isValid ? builtPolicy.displayLabel : "—")
                        .foregroundStyle(isValid ? .primary : .secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .listStyle(.plain)
        .navigationTitle("Custom Rule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") { onContinue(builtPolicy) }
                    .disabled(!isValid)
            }
        }
        .onChange(of: selectedWindowMinutes) { newWindow in
            // Auto-correct allowance if it's no longer valid for the new window
            if selectedAllowance >= newWindow {
                let valid = allAllowanceOptions.filter { $0 < newWindow }
                selectedAllowance = valid.last ?? allAllowanceOptions[0]
            }
        }
    }

    private func pickerLabel(_ m: Int) -> String {
        let h = m / 60, mins = m % 60
        if h == 0 { return mins == 1 ? "1 minute" : "\(mins) minutes" }
        if mins == 0 { return h == 1 ? "1 hour" : "\(h) hours" }
        return "\(h)h \(mins)m"
    }
}

// MARK: - Rule Setup Screen (name + apps + active days)

private struct RuleSetupScreen: View {
    let policy: UsagePolicy
    let onSave: (AppRule) -> Void

    @State private var ruleName = ""
    @State private var selection = FamilyActivitySelection()
    @State private var activeDays: Set<Int> = Set(1...7)
    @State private var showPicker = false
    @State private var unlockDurationKey: String = "default"
    @State private var frictionKey: String = "default"
    @State private var showFrictionPreview = false

    private var resolvedPreviewFriction: FrictionType {
        if frictionKey == "default" {
            return AppGroupStore.shared.loadSettings().defaultFriction
        }
        return FrictionType(rawValue: frictionKey) ?? .confirmOnly
    }

    private var unlockDuration: UnlockType?   { UnlockType(rawValue: unlockDurationKey) }
    private var frictionOverride: FrictionType? { FrictionType(rawValue: frictionKey) }

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    private var isValid: Bool {
        hasSelection && !ruleName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var selectionSummary: String {
        let a = selection.applicationTokens.count
        let c = selection.categoryTokens.count
        if a == 0 && c == 0 { return "Tap to choose apps" }
        var parts: [String] = []
        if a > 0 { parts.append("\(a) app\(a == 1 ? "" : "s")") }
        if c > 0 { parts.append("\(c) categor\(c == 1 ? "y" : "ies")") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        Form {
            // Policy summary — shows what they chose
            Section {
                HStack(spacing: 10) {
                    Image(systemName: policy.type == .daily ? "sun.max.fill" : "timer")
                        .foregroundStyle(Color.scrollGremlinPrimary)
                    Text(policy.displayLabel)
                        .fontWeight(.medium)
                    Spacer()
                }
            } header: {
                Text("Limit")
            }

            Section("Rule Name") {
                TextField("e.g. Social Media", text: $ruleName)
                }

            Section("Apps to Block") {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Text(selectionSummary)
                            .foregroundStyle(hasSelection ? .primary : .secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
            }

            Section("Active Days") {
                ActiveDaysPicker(activeDays: $activeDays)
                }

            Section("Blocking Duration") {
                Picker("Duration", selection: $unlockDurationKey) {
                    Text("Default (follows Settings)").tag("default")
                    ForEach(UnlockType.allCases, id: \.rawValue) { type in
                        Text(type.displayLabel).tag(type.rawValue)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Blocking Friction") {
                Picker("Friction", selection: $frictionKey) {
                    Text("Default (follows Settings)").tag("default")
                    ForEach(FrictionType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }
                .pickerStyle(.navigationLink)

                Button {
                    showFrictionPreview = true
                } label: {
                    Label("Preview selected friction", systemImage: "play.circle")
                        .foregroundStyle(Color.scrollGremlinPrimary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .listStyle(.plain)
        .navigationTitle("Rule Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let rule = AppRule(
                        name: ruleName.trimmingCharacters(in: .whitespaces),
                        selection: selection,
                        policy: policy,
                        schedule: RuleSchedule(
                            activeDays: activeDays,
                            startHour: 0, startMinute: 0,
                            endHour: 23, endMinute: 59
                        ),
                        frictionOverride: frictionOverride,
                        unlockDurationOverride: unlockDuration
                    )
                    onSave(rule)
                }
                .disabled(!isValid)
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .fullScreenCover(isPresented: $showFrictionPreview) {
            FrictionPreviewView(friction: resolvedPreviewFriction)
        }
    }
}
