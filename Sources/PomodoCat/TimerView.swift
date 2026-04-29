import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 36)
                .padding(.top, 32)

            Spacer(minLength: 20)

            timerCard
                .padding(.horizontal, 36)

            Spacer(minLength: 20)

            phasePills
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.phase.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(viewModel.phase.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            sessionsBadge
        }
    }

    private var sessionsBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.accentGradient)
            Text("\(viewModel.completedFocusSessions) sessions")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(Theme.cardBackground)
        )
        .overlay(
            Capsule().stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var timerCard: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: max(0.001, viewModel.progress))
                    .stroke(viewModel.phase.gradient,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: viewModel.progress)

                VStack(spacing: 6) {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Text(viewModel.isRunning ? "En cours" : "En pause")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
            }
            .frame(width: 280, height: 280)

            controls
        }
        .padding(36)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var controls: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "arrow.counterclockwise") {
                viewModel.reset()
            }

            PrimaryActionButton(
                title: viewModel.isRunning ? "Pause" : "Démarrer",
                icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                gradient: viewModel.phase.gradient
            ) {
                viewModel.toggle()
            }

            CircleIconButton(systemName: "forward.end.fill") {
                viewModel.skip()
            }
        }
    }

    private var phasePills: some View {
        HStack(spacing: 8) {
            phasePill(.focus, label: "25 min")
            phasePill(.shortBreak, label: "5 min")
            phasePill(.longBreak, label: "15 min")
        }
    }

    private func phasePill(_ phase: SessionPhase, label: String) -> some View {
        let active = viewModel.phase == phase
        return HStack(spacing: 6) {
            Circle()
                .fill(active ? AnyShapeStyle(phase.gradient) : AnyShapeStyle(Color.white.opacity(0.2)))
                .frame(width: 6, height: 6)
            Text(phase.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(active ? Theme.textPrimary : Theme.textTertiary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(active ? Color.white.opacity(0.06) : .clear)
        )
        .overlay(
            Capsule().stroke(active ? Theme.stroke : .clear, lineWidth: 1)
        )
    }
}

private struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(minWidth: 140)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            )
            .scaleEffect(hovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(hovering ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                )
                .overlay(
                    Circle().stroke(Theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
