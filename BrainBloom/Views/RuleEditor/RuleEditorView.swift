import SwiftUI
import FamilyControls

struct RuleEditorView: View {
    @StateObject private var viewModel: RuleEditorViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: (AppRule) -> Void
    let onDelete: (() -> Void)?
    private let embedsInNavigationStack: Bool

    @State private var showFrictionPreview = false

    private var resolvedPreviewFriction: FrictionType {
        if viewModel.frictionKey == "default" {
            return viewModel.defaultFriction
        }
        return FrictionType(rawValue: viewModel.frictionKey) ?? .confirmOnly
    }

    init(
        rule: AppRule? = nil,
        onDelete: (() -> Void)? = nil,
        embedsInNavigationStack: Bool = true,
        onSave: @escaping (AppRule) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RuleEditorViewModel(rule: rule))
        self.onDelete = onDelete
        self.embedsInNavigationStack = embedsInNavigationStack
        self.onSave = onSave
    }

    /// Opens the editor pre-populated with a schedule template (e.g. Work 9-5).
    /// All fields are fully editable; the rule is treated as new (no Delete button).
    init(
        templateSchedule: RuleSchedule,
        embedsInNavigationStack: Bool = true,
        onSave: @escaping (AppRule) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RuleEditorViewModel(templateSchedule: templateSchedule))
        self.onDelete = nil
        self.embedsInNavigationStack = embedsInNavigationStack
        self.onSave = onSave
    }

    var body: some View {
        Group {
            if embedsInNavigationStack {
                NavigationStack {
                    content
                }
            } else {
                content
            }
        }
        .toolbarBackground(.regularMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: $showFrictionPreview) {
            FrictionPreviewView(friction: resolvedPreviewFriction)
        }
    }

    private var content: some View {
        ZStack {
            RuleFlowBackground()

            Form {
                Section {
                    TextField("", text: $viewModel.ruleName, prompt: ruleNamePrompt)
                } header: {
                    sectionHeader(RuleFlowCopy.ruleNameTitle)
                }

                Section {
                    Button(action: { viewModel.showPicker = true }) {
                        HStack {
                            Text(viewModel.selectionSummary)
                                .foregroundStyle(viewModel.hasSelection ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    sectionHeader(RuleFlowCopy.appsToBlockTitle)
                }

                Section {
                    Picker("Limit Type", selection: $viewModel.ruleMode) {
                        Text("Daily").tag(RuleMode.daily)
                        Text("Hourly").tag(RuleMode.hourly)
                        Text("Scheduled").tag(RuleMode.scheduledWindow)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    sectionHeader(RuleFlowCopy.limitTypeTitle)
                } footer: {
                    Text(viewModel.ruleMode.helperText)
                }

                Section {
                    LimitPickerRow(minutes: $viewModel.allowedMinutes, maxMinutes: viewModel.maxAllowanceMinutes)

                    if viewModel.ruleMode == .hourly {
                        IntervalPickerRow(hours: $viewModel.intervalHours)
                    }
                } header: {
                    sectionHeader(RuleFlowCopy.allowanceTitle)
                } footer: {
                    if let message = viewModel.policyValidationMessage {
                        Text(message)
                    }
                }

                if viewModel.ruleMode == .scheduledWindow {
                    Section {
                        ActiveDaysPicker(activeDays: $viewModel.activeDays)
                        DatePicker("Start", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                } header: {
                    sectionHeader(RuleFlowCopy.scheduleTitle)
                } footer: {
                    if let message = viewModel.scheduleValidationMessage {
                        Text(message)
                        }
                    }
                }

                Section {
                    Picker("Duration", selection: $viewModel.unlockDurationKey) {
                        Text(viewModel.defaultUnlockType.displayLabel).tag("default")
                        ForEach(UnlockType.allCases.filter { $0 != viewModel.defaultUnlockType }, id: \.rawValue) { type in
                            Text(type.displayLabel).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    sectionHeader(RuleFlowCopy.blockingDurationTitle)
                }

                Section {
                    Picker("Friction", selection: $viewModel.frictionKey) {
                        Text(viewModel.defaultFriction.displayName).tag("default")
                        ForEach(FrictionType.allCases.filter { $0 != viewModel.defaultFriction }, id: \.rawValue) { type in
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
                } header: {
                    sectionHeader(RuleFlowCopy.blockingFrictionTitle)
                }

                if viewModel.isEditing {
                    Section {
                        Button("Delete Rule", role: .destructive) {
                            viewModel.requestDelete = true
                        }
                    } header: {
                        sectionHeader(RuleFlowCopy.dangerZoneTitle)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .navigationTitle(viewModel.isEditing ? "Edit Rule" : "New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let rule = viewModel.buildRule() {
                            onSave(rule)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.showPicker,
            selection: $viewModel.selection
        )
        .alert("Delete Rule?", isPresented: $viewModel.requestDelete) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.ruleMode) { newMode in
            if newMode != .scheduledWindow {
                viewModel.resetScheduleToAllDay()
            }
        }
        .onChange(of: viewModel.intervalHours) { _ in
            let maxMinutes = viewModel.maxAllowanceMinutes
            if viewModel.allowedMinutes > maxMinutes {
                viewModel.allowedMinutes = maxMinutes
            }
        }
        .onChange(of: viewModel.startHour) { _ in clampAllowanceToWindow() }
        .onChange(of: viewModel.startMinute) { _ in clampAllowanceToWindow() }
        .onChange(of: viewModel.endHour) { _ in clampAllowanceToWindow() }
        .onChange(of: viewModel.endMinute) { _ in clampAllowanceToWindow() }
    }

    private func clampAllowanceToWindow() {
        let maxMinutes = viewModel.maxAllowanceMinutes
        if viewModel.allowedMinutes > maxMinutes {
            viewModel.allowedMinutes = maxMinutes
        }
    }

    private var ruleNamePrompt: Text {
        Text("e.g. Social Media").foregroundColor(.secondary)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .textCase(nil)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }

    // MARK: - Time bindings

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                c.hour = viewModel.startHour; c.minute = viewModel.startMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                viewModel.startHour   = Calendar.current.component(.hour,   from: date)
                viewModel.startMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: {
                var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                c.hour = viewModel.endHour; c.minute = viewModel.endMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                viewModel.endHour   = Calendar.current.component(.hour,   from: date)
                viewModel.endMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }
}

struct LimitPickerRow: View {
    @Binding var minutes: Int
    let maxMinutes: Int

    private var options: [Int] {
        let upper = max(0, maxMinutes)
        if upper < 5 {
            return [0]
        }
        return [0] + Array(stride(from: 5, through: upper, by: 5))
    }

    var body: some View {
        HStack {
            Text("Allowance")
            Spacer()
            Picker("Allowance", selection: $minutes) {
                ForEach(options, id: \.self) { min in
                    Text(formatMinutes(min)).tag(min)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 140, height: 80)
            .clipped()
        }
    }

    private func formatMinutes(_ total: Int) -> String {
        let hours = total / 60
        let mins = total % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}

struct IntervalPickerRow: View {
    @Binding var hours: Int

    private let options = Array(1...24)

    var body: some View {
        HStack {
            Text("Reset Window")
            Spacer()
            Picker("Reset Window", selection: $hours) {
                ForEach(options, id: \.self) { value in
                    Text(value == 1 ? "Every hour" : "Every \(value) hours").tag(value)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct ActiveDaysPicker: View {
    @Binding var activeDays: Set<Int>

    private let days = [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.0) { (dayNum, label) in
                DayChip(
                    label: label,
                    isSelected: activeDays.contains(dayNum),
                    onTap: {
                        if activeDays.contains(dayNum) {
                            if activeDays.count > 1 { activeDays.remove(dayNum) }
                        } else {
                            activeDays.insert(dayNum)
                        }
                    }
                )
            }
        }
    }
}

#Preview("New Rule") {
    RuleEditorView { _ in }
}

#Preview("Edit Recurring Rule") {
    RuleEditorView(
        rule: AppRule(
            name: "Social Media",
            selection: FamilyActivitySelection(),
            policy: .recurring(minutes: 20, everyHours: 1),
            schedule: .allDayEveryDay
        ),
        onDelete: {}
    ) { _ in }
}

#Preview("Edit Scheduled Window") {
    RuleEditorView(
        rule: AppRule(
            name: "Work Focus",
            selection: FamilyActivitySelection(),
            policy: .daily(minutes: 30),
            schedule: .workDays
        ),
        onDelete: {}
    ) { _ in }
}

private struct DayChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption2).fontWeight(isSelected ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Color.scrollGremlinPrimary : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
