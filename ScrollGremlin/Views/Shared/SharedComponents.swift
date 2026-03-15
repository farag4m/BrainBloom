import SwiftUI

struct AddRuleButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: scheme == .dark
                                ? [Color.white.opacity(0.20), Color.clear]
                                : [Color.white.opacity(0.45), Color.clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.6)
                        )
                    )
                    .frame(width: 36, height: 36)

                Circle()
                    .stroke(Color.white.opacity(scheme == .dark ? 0.22 : 0.50), lineWidth: 1)
                    .frame(width: 36, height: 36)

                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.90))
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 10, y: 4)
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
