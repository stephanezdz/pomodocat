import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case sessions = "Sessions"
    case stats = "Statistiques"
    case settings = "Réglages"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timer: return "timer"
        case .sessions: return "square.stack.3d.up"
        case .stats: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(
                        item: item,
                        isSelected: selection == item
                    ) {
                        selection = item
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            footer
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .frame(width: 220)
        .background(Theme.sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.stroke)
                .frame(width: 1)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accentGradient)
                    .frame(width: 34, height: 34)
                Text("🐱")
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("PomodoCat")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Focus & félins")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text("Prêt")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("v0.1")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

private struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(background)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var background: Color {
        if isSelected { return Color.white.opacity(0.08) }
        if hovering { return Color.white.opacity(0.04) }
        return .clear
    }
}
