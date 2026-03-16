import SwiftUI

struct AddRuleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.sgTeal, Color.sgTealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                scheme == .dark
                    ? Color.white.opacity(0.75)
                    : Color(red: 0.18, green: 0.26, blue: 0.48)
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: scheme == .dark ? [
                                    Color(red: 0.20, green: 0.12, blue: 0.45).opacity(0.50),
                                    Color.clear,
                                ] : [
                                    Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.18),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.45), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(scheme == .dark ? 0.30 : 0.08), radius: 8, y: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}

struct StatusBadgeView: View {
    let badge: RuleStatusBadge
    var onColoredSurface: Bool = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(onColoredSurface ? Color.white : badge.color)
                .frame(width: 6, height: 6)

            Text(badge.label)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            ZStack {
                Capsule()
                    .fill(
                        onColoredSurface
                            ? Color.white.opacity(0.25)
                            : (scheme == .dark ? badge.color.opacity(0.22) : badge.color.opacity(0.15))
                    )

                Capsule()
                    .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.40), lineWidth: 0.5)
            }
        }
        .foregroundStyle(onColoredSurface ? .white : badge.color)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: badge)
    }
}

struct EmptyRulesState: View {
    let onAddRule: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add a rule to start building healthier app habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddRule) { Label("Add First Rule", systemImage: "plus") }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 228)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

struct GlassLeafIcon: View {
    let size: CGFloat
    var tint: Color = Color.sgTeal
    var glassTint: Color = Color.sgTeal.opacity(0.35)

    var body: some View {
        ZStack {
            glassBackdrop

            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var glassBackdrop: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
            .overlay(
                Circle()
                    .fill(glassTint.opacity(0.18))
            )
            .frame(width: size, height: size)
    }
}
