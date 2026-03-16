import SwiftUI

struct SettingsView: View {
    @State private var settings = AppGroupStore.shared.loadSettings()
    @EnvironmentObject var authManager: AuthorizationManager
    @State private var showExportSheet = false
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()
            NavigationStack {
            Form {
                Section {
                    Picker("Default Friction", selection: $settings.defaultFriction) {
                        ForEach(FrictionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Picker("Default Unlock Duration", selection: $settings.defaultUnlockType) {
                        ForEach(UnlockType.allCases, id: \.self) { type in
                            Text(type.displayLabel).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Toggle("Require Intention Text", isOn: $settings.requireIntentionText)
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("These are used when a rule is set to Default. Individual rules can override them.")
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)

                    if settings.notificationsEnabled {
                        Picker("Warning Time", selection: $settings.warningMinutes) {
                            Text("Off").tag(0)
                            Text("5 min before").tag(5)
                            Text("10 min before").tag(10)
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                Section("Display") {
                    Picker("Appearance", selection: $settings.colorScheme) {
                        Text("Light").tag(AppColorScheme.light)
                        Text("Dark").tag(AppColorScheme.dark)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Show Streak Counter", isOn: $settings.showStreakCounter)
                }

                Section("Data") {
                    Button("Export Data") {
                        showExportSheet = true
                    }

                    Button("Clear History", role: .destructive) {
                        showResetAlert = true
                    }
                }

                Section("Debug") {
                    NavigationLink("Screen Time Simulator") {
                        ScreenTimeDebugView()
                    }
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("App Group") {
                        Text(AppGroupStore.appGroupID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle("Settings")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(.clear)
        } // ZStack
        .onChange(of: settings) { newSettings in
            AppGroupStore.shared.saveSettings(newSettings)
        }
        .alert("Clear History?", isPresented: $showResetAlert) {
            Button("Clear", role: .destructive) {
                AppGroupStore.shared.clearUnlockSessions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all unlock history.")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView()
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(exportText)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: exportText)
                }
            }
        }
        .onAppear {
            let store = AppGroupStore.shared
            let sessions = store.loadUnlockSessions()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(sessions),
               let json = String(data: data, encoding: .utf8) {
                exportText = json
            } else {
                exportText = "[]"
            }
        }
    }
}
