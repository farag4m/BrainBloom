import SwiftUI

struct OnboardingPermissionView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    let onAuthorized: () -> Void

    @State private var isRequesting = false

    var body: some View {
        ZStack {
            GradientBackground().ignoresSafeArea()

            // Ambient violet glow — top-left
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.55, green: 0.40, blue: 0.92).opacity(0.18), Color.clear],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 320, height: 320)
                .offset(x: -140, y: -180)
                .blur(radius: 30)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Mascot halo
                    ZStack {
                        SGMascotGlow(size: 160)
                        Circle()
                            .stroke(Color.sgTeal.opacity(0.22), lineWidth: 1)
                            .frame(width: 140, height: 140)
                        Image("Gremlin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.sgTeal.opacity(0.25), radius: 14, y: 5)
                    }

                    Text("Screen Time Access")
                        .font(.title2.weight(.bold)).foregroundStyle(.primary)

                    Text("\(AppName.displayName) needs Screen Time access to monitor app usage and apply blocks when your limits are reached.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Spacer()

                VStack(spacing: 10) {
                    PermissionInfoRow(icon: "eye.slash",
                                     title: "Privacy first",
                                     detail: "App usage data never leaves your device")
                    PermissionInfoRow(icon: "shield.lefthalf.filled",
                                     title: "You're in control",
                                     detail: "No parental lock or PIN required")
                    PermissionInfoRow(icon: "arrow.counterclockwise",
                                     title: "Revokable anytime",
                                     detail: "Disable in Settings > Screen Time")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                if authManager.status == .denied {
                    VStack(spacing: 12) {
                        Text("Screen Time access was denied. Please enable it in Settings.")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.85))
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
                .padding(.bottom, 52)
            }
        }
        .onChange(of: authManager.status) { newStatus in
            if newStatus == .authorized { onAuthorized() }
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.sgTeal.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(Color.sgTeal)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .sgCard(cornerRadius: 14)
    }
}
