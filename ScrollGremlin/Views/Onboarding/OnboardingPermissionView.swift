import SwiftUI

struct OnboardingPermissionView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    let onAuthorized: () -> Void

    @State private var isRequesting = false
    @State private var showDeniedAlert = false

    var body: some View {
        ZStack {
            Color.scrollGremlinBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.scrollGremlinPrimary.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.scrollGremlinPrimary)
                    }

                    Text("Screen Time Access")
                        .font(.title2).fontWeight(.bold).foregroundStyle(.white)

                    Text("ScrollGremlin needs Screen Time access to monitor app usage and apply blocks when your limits are reached.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Spacer()

                VStack(spacing: 12) {
                    PermissionInfoRow(
                        icon: "eye.slash",
                        title: "Privacy first",
                        detail: "App usage data never leaves your device"
                    )
                    PermissionInfoRow(
                        icon: "shield.lefthalf.filled",
                        title: "You're in control",
                        detail: "No parental lock or PIN required"
                    )
                    PermissionInfoRow(
                        icon: "arrow.counterclockwise",
                        title: "Revokable anytime",
                        detail: "Disable in Settings > Screen Time"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                if authManager.status == .denied {
                    VStack(spacing: 12) {
                        Text("Screen Time access was denied. Please enable it in Settings.")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)
                }

                Button(action: requestAccess) {
                    if isRequesting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Allow Access")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onChange(of: authManager.status) { newStatus in
            if newStatus == .authorized {
                onAuthorized()
            }
        }
    }

    private func requestAccess() {
        isRequesting = true
        Task {
            await authManager.requestAuthorization()
            isRequesting = false
        }
    }
}

private struct PermissionInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.scrollGremlinPrimary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium).foregroundStyle(.white)
                Text(detail).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding()
        .background(Color.scrollGremlinSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
