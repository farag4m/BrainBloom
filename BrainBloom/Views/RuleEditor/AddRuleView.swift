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
    private let defaults = RuleFlowDefaults.current()

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                RuleFlowBackground()

                PresetsScreen(
                    onNavigate: { destination in navPath.append(destination) },
                    onWorkPreset: { navPath.append(AddRuleDest.workTemplate) }
                )
                .navigationDestination(for: AddRuleDest.self) { destination in
                    switch destination {
                    case .custom:
                        RuleEditorView(embedsInNavigationStack: false) { rule in
                            onSave(rule)
                            dismiss()
                        }
                    case .setup(let policy):
                        RuleSetupScreen(policy: policy, defaults: defaults) { rule in
                            onSave(rule)
                            dismiss()
                        }
                    case .workTemplate:
                        RuleEditorView(templateSchedule: .workDays, embedsInNavigationStack: false) { rule in
                            onSave(rule)
                            dismiss()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .toolbarBackground(.regularMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    AddRuleView { _ in }
}

// MARK: - Navigation destination

enum AddRuleDest: Hashable {
    case custom
    case setup(UsagePolicy)
    case workTemplate
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
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
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
                Text("Work (9-5)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Mon-Fri schedule")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(minHeight: 100)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Rule Setup Screen (name + apps + active days)

private struct RuleSetupScreen: View {
    let policy: UsagePolicy
    let defaults: RuleFlowDefaults
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
            return defaults.defaultFriction
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
            // Policy summary - shows what they chose
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

            Section(RuleFlowCopy.ruleNameTitle) {
                TextField("e.g. Social Media", text: $ruleName)
                }

            Section(RuleFlowCopy.appsToBlockTitle) {
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

            Section(RuleFlowCopy.scheduleTitle) {
                ActiveDaysPicker(activeDays: $activeDays)
                }

            Section(RuleFlowCopy.blockingDurationTitle) {
                Picker("Duration", selection: $unlockDurationKey) {
                    Text(defaults.defaultUnlockType.displayLabel).tag("default")
                    ForEach(UnlockType.allCases.filter { $0 != defaults.defaultUnlockType }, id: \.rawValue) { type in
                        Text(type.displayLabel).tag(type.rawValue)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section(RuleFlowCopy.blockingFrictionTitle) {
                Picker("Friction", selection: $frictionKey) {
                    Text(defaults.defaultFriction.displayName).tag("default")
                    ForEach(FrictionType.allCases.filter { $0 != defaults.defaultFriction }, id: \.rawValue) { type in
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
