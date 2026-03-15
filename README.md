# ScrollGremlin

ScrollGremlin is an iOS Screen Time companion built around `FamilyControls`, `DeviceActivity`, and `ManagedSettings`. It lets the main app define blocking rules, lets extensions enforce those rules, and stores shared state in an app group so each target can read the same data.

## Current Status

- The repository has been recovered to a consistent Xcode state after an earlier branch/project-file mismatch.
- `demo`, `main`, and `backup` were aligned to the same working commit during recovery.
- The Xcode project now builds successfully with:
  `xcodebuild -project ScrollGremlin.xcodeproj -scheme ScrollGremlin -destination 'generic/platform=iOS Simulator' build`
- The codebase has gone through a cleanup pass focused on readability, maintainability, state ownership, and dead-code removal.

## Recovery And Cleanup Timeline

### 1. Repository recovery

The repository was initially left in a mixed state:

- `demo` pointed to an older `IntentBlock` snapshot.
- `main` contained the newer renamed `ScrollGremlin` work.
- stale filesystem leftovers from another branch were still present in the working directory.
- Xcode was opening an incomplete `.xcodeproj` bundle and reporting that the project file was missing.

The recovery steps were:

1. Validate the tracked project in Git.
2. Remove stale untracked `ScrollGremlin` leftovers that were confusing Xcode.
3. Fast-forward `demo` to the same commit as `main`.
4. Create `backup` so all three branches preserve the recovered state.

### 2. State-management cleanup

The first code cleanup pass focused on ownership and consistency:

- `RuleManager` became the single mutation owner for rule persistence and monitoring updates.
- `DashboardViewModel` stopped duplicating persistence logic.
- badge/status calculation was centralized so views and view models use the same rule-state decision path.
- unlock session recording was corrected to store the effective friction rather than the default friction.
- appearance settings were normalized to explicit light or dark mode only.

### 3. Dead-code and asset cleanup

The second pass removed low-value clutter:

- deleted the unused `NotificationService`.
- removed unused view-model state that was no longer read.
- removed reference-only design assets from `Assets.xcassets`.
- cleaned up stale comments and legacy helper aliases.
- fixed a `ManagedSettings` warning in `MonitoringService`.

### 4. Shared design-layer split

The original `DesignSystem.swift` had grown into a mixed file containing:

- brand tokens
- gradients
- backgrounds
- card surfaces
- shared UI components
- button styles

That file has now been split into:

- `Views/Shared/DesignTokens.swift`
- `Views/Shared/BackgroundSurfaces.swift`
- `Views/Shared/SharedComponents.swift`
- `Views/Shared/ButtonStyles.swift`

This makes the visual system easier to navigate and lowers the chance of unrelated UI responsibilities piling into one file again.

## Project Goals

- Keep rule creation and editing simple.
- Keep enforcement logic centralized and predictable.
- Keep cross-target data shared through a single storage boundary.
- Keep SwiftUI views focused on presentation instead of persistence details.
- Keep state ownership singular where possible so UI and enforcement logic cannot drift apart.

## Target Overview

- `ScrollGremlin/`
  Main iOS app target. Owns onboarding, rule editing, history, settings, and unlock flows.
- `ScrollGremlinMonitor/`
  Device activity monitor extension. Responds to Screen Time callbacks.
- `ScrollGremlinShieldAction/`
  Shield action extension for unlock requests.
- `ScrollGremlinShieldConfig/`
  Shield configuration extension for the lock screen UI.
- `ScrollGremlinReport/`
  Report extension target.
- `Shared/`
  Models and shared persistence code used across targets.

## Folder Structure

### Main app

- `ScrollGremlin/App/`
  App entry point and root navigation.
- `ScrollGremlin/Services/`
  App-level coordinators such as authorization, rule management, and monitoring.
- `ScrollGremlin/ViewModels/`
  Presentation state for SwiftUI screens. View models derive UI state and delegate mutations to services.
- `ScrollGremlin/Views/`
  Screen and component hierarchy grouped by feature area.
- `ScrollGremlin/Resources/`
  Entitlements and app target resources.
- `ScrollGremlin/Assets.xcassets/`
  Production image assets only.

### Shared

- `Shared/Models.swift`
  Domain models, schedules, unlock metadata, and shared enums.
- `Shared/AppGroupStore.swift`
  The single persistence boundary for data stored in the app group.

### Shared design layer

- `ScrollGremlin/Views/Shared/DesignTokens.swift`
  Brand colors, gradients, and appearance helpers.
- `ScrollGremlin/Views/Shared/BackgroundSurfaces.swift`
  Page backgrounds, card surfaces, mascot framing, and reusable surface modifiers.
- `ScrollGremlin/Views/Shared/SharedComponents.swift`
  Reusable UI components such as section headers, badges, and toolbar buttons.
- `ScrollGremlin/Views/Shared/ButtonStyles.swift`
  Shared button styles.

## Architecture

### Data flow

1. SwiftUI views bind to view models.
2. View models derive display state and call services for mutations.
3. `RuleManager` is the source of truth for rule CRUD and monitoring updates.
4. `AppGroupStore` persists shared state for the app and extensions.
5. Extensions read shared state and enforce the correct behavior outside the main app.

### Responsibility boundaries

- `RuleManager`
  Owns rule persistence and starts or stops monitoring when rules change.
- `MonitoringService`
  Encapsulates `DeviceActivityCenter` and `ManagedSettingsStore` interactions.
- `AuthorizationManager`
  Encapsulates Family Controls authorization state.
- `AppGroupStore`
  Encodes and decodes app group data. It should not contain UI logic.
- View models
  Build display-ready state, react to lifecycle changes, and delegate writes to services.
- Views
  Render data, collect user input, and avoid direct persistence when possible.

## Shared Models

- `AppRule`
  A saved blocking rule with app selection, usage policy, schedule, and optional per-rule overrides.
- `UsagePolicy`
  Describes either a daily limit or a recurring interval limit.
- `RuleSchedule`
  Describes active days and active hours.
- `DailyState`
  Stores per-rule state for the current day.
- `UnlockSession`
  Records a completed unlock flow.
- `UserSettings`
  Stores global defaults such as friction, duration, notifications, and appearance.
- `MonitorPolicy`
  A lightweight snapshot written by the app and consumed by extensions.

## Code Organization Rules

- Add new domain models to `Shared/` only when they are used across targets.
- Keep persistence writes inside services or `AppGroupStore`, not in SwiftUI views.
- Prefer one owner per mutable domain area. For rules, that owner is `RuleManager`.
- Keep `MonitoringService` focused on Screen Time APIs instead of UI state.
- Add comments only where behavior is non-obvious or cross-target constraints matter.
- Avoid storing temporary references, mock assets, or discarded experiments in production folders.

## Important Cleanup Decisions

### Single decision points

The codebase was adjusted to reduce split-brain state:

- rule persistence now flows through `RuleManager`.
- shield/badge status derives from a shared rule-status decision path.
- unlock-flow intent requirements now respect one computed path rather than scattered conditionals.

### Removed code

The following categories were intentionally removed:

- unused services
- unused state properties
- dead design helpers and aliases
- reference-only asset catalog entries

If a removed piece is needed later, it should be reintroduced only with a clear caller and a defined responsibility.

## Remaining Tradeoffs

- The project still relies on several singletons (`RuleManager`, `MonitoringService`, `AuthorizationManager`, `AppGroupStore`) for convenience. This keeps the app simple, but it limits testability and dependency injection.
- The shared design layer is now split, but the app still has rich UI code in several feature views. If the visual language keeps growing, more shared extraction may make sense.
- There is still no test suite covering scheduling, recurring slot registration, or unlock-state persistence.

## Recommended Next Steps

- Add tests around schedule calculation, recurring slot behavior, and unlock-state persistence.
- Consider protocol-based abstractions for services if unit testing becomes a priority.
- Keep new UI helpers inside the shared design files that match their responsibility instead of creating another catch-all file.
- Keep future branch operations isolated so Xcode project bundles are not mixed across branch checkouts.

## Opening The Project

Open `ScrollGremlin.xcodeproj` in Xcode. The app and all extension targets are configured there.
