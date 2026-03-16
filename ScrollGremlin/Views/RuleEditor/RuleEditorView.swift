import SwiftUI
import FamilyControls

struct RuleEditorView: View {
    @StateObject private var viewModel: RuleEditorViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: (AppRule) -> Void
    let onDelete: (() -> Void)?

    @State private var showFrictionPreview = false

    private var defaultUnlockType: UnlockType {
        AppGroupStore.shared.loadSettings().defaultUnlockType
    }

    private var defaultFriction: FrictionType {
        AppGroupStore.shared.loadSettings().defaultFriction
    }

    private var resolvedPreviewFriction: FrictionType {
        if viewModel.frictionKey == "default" {
            return AppGroupStore.shared.loadSettings().defaultFriction
        }
        return FrictionType(rawValue: viewModel.frictionKey) ?? .confirmOnly
    }

    init(rule: AppRule? = nil, onDelete: (() -> Void)? = nil, onSave: @escaping (AppRule) -> Void) {
        _viewModel = StateObject(wrappedValue: RuleEditorViewModel(rule: rule))
        self.onDelete = onDelete
        self.onSave = onSave
    }

    /// Opens the editor pre-populated with a schedule template (e.g. Work 9–5).
    /// All fields are fully editable; the rule is treated as new (no Delete button).
    init(templateSchedule: RuleSchedule, onSave: @escaping (AppRule) -> Void) {
        _viewModel = StateObject(wrappedValue: RuleEditorViewModel(templateSchedule: templateSchedule))
        self.onDelete = nil
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("", text: $viewModel.ruleName, prompt: ruleNamePrompt)
                } header: {
                    sectionHeader("Rule Name")
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
                    sectionHeader("Apps to Block")
                }

                Section {
                    Picker("Limit Type", selection: $viewModel.ruleMode) {
                        Text("Daily").tag(RuleEditorViewModel.RuleMode.daily)
                        Text("Hourly").tag(RuleEditorViewModel.RuleMode.hourly)
                        Text("Scheduled").tag(RuleEditorViewModel.RuleMode.scheduledWindow)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    sectionHeader("Limit Type")
                } footer: {
                    Text(viewModel.ruleMode.helperText)
                }

                Section {
                    LimitPickerRow(minutes: $viewModel.allowedMinutes)
                } header: {
                    sectionHeader("Allowance")
                }

                if viewModel.ruleMode == .scheduledWindow {
                    Section {
                        ActiveDaysPicker(activeDays: $viewModel.activeDays)
                        DatePicker("Start", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                    } header: {
                        sectionHeader("Schedule")
                    }
                }

                Section {
                    Picker("Duration", selection: $viewModel.unlockDurationKey) {
                        Text(defaultUnlockType.displayLabel).tag("default")
                        ForEach(UnlockType.allCases.filter { $0 != defaultUnlockType }, id: \.rawValue) { type in
                            Text(type.displayLabel).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    sectionHeader("Blocking Duration")
                }

                Section {
                    Picker("Friction", selection: $viewModel.frictionKey) {
                        Text(defaultFriction.displayName).tag("default")
                        ForEach(FrictionType.allCases.filter { $0 != defaultFriction }, id: \.rawValue) { type in
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
                    sectionHeader("Blocking Friction")
                }

                if viewModel.isEditing {
                    Section {
                        Button("Delete Rule", role: .destructive) {
                            viewModel.requestDelete = true
                        }
                    } header: {
                        sectionHeader("Danger Zone")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.clear)
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
            .background(.clear)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: viewModel.ruleMode) { newMode in
                if newMode != .scheduledWindow {
                    viewModel.resetScheduleToAllDay()
                }
            }
        }
        .fullScreenCover(isPresented: $showFrictionPreview) {
            FrictionPreviewView(friction: resolvedPreviewFriction)
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

    private let options: [Int] = [0] + Array(stride(from: 5, through: 23 * 60 + 55, by: 5))

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
