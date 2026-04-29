import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var selection: CatSelection
    @ObservedObject var preferences: Preferences
    @State private var cats: [Cat] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                pomodoroTheory
                durationsSection
                behaviorSection
                catLibrarySection
            }
            .padding(36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { rescan() }
        .onChange(of: selection.refreshToken) { _ in rescan() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            rescan()
        }
    }

    private func rescan() {
        cats = CatLibrary.allCats()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Réglages")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Ajuste les durées, les comportements et choisis ton chat")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Theory

    private var pomodoroTheory: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("🍅")
                        .font(.system(size: 22))
                    Text("La technique Pomodoro")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                Text("Inventée à la fin des années 1980 par Francesco Cirillo, la méthode Pomodoro découpe le travail en intervalles courts de concentration intense (25 min) séparés par de petites pauses (5 min). Toutes les quatre sessions, on prend une pause longue (15 à 30 min). Cette cadence respecte les limites naturelles de l'attention et permet de maintenir un rythme soutenable sur la durée.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Durations

    private var durationsSection: some View {
        SettingsSection(title: "Durées") {
            VStack(spacing: 14) {
                DurationRow(
                    label: "Focus",
                    value: $preferences.focusMinutes,
                    range: Preferences.focusRange,
                    defaultValue: Preferences.Defaults.focusMinutes,
                    accent: Theme.focusGradient
                ) { preferences.resetFocus() }

                Divider().overlay(Theme.stroke)

                DurationRow(
                    label: "Pause courte",
                    value: $preferences.shortBreakMinutes,
                    range: Preferences.shortRange,
                    defaultValue: Preferences.Defaults.shortBreakMinutes,
                    accent: Theme.breakGradient
                ) { preferences.resetShortBreak() }

                Divider().overlay(Theme.stroke)

                DurationRow(
                    label: "Pause longue",
                    value: $preferences.longBreakMinutes,
                    range: Preferences.longRange,
                    defaultValue: Preferences.Defaults.longBreakMinutes,
                    accent: Theme.longBreakGradient
                ) { preferences.resetLongBreak() }

                Divider().overlay(Theme.stroke)

                DurationRow(
                    label: "Pause longue toutes les",
                    value: $preferences.sessionsBeforeLongBreak,
                    range: Preferences.cycleRange,
                    defaultValue: Preferences.Defaults.sessionsBeforeLongBreak,
                    unit: "sessions",
                    accent: Theme.accentGradient
                ) { preferences.resetCycle() }
            }
        }
    }

    // MARK: - Behavior toggles

    private var behaviorSection: some View {
        SettingsSection(title: "Comportement") {
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Afficher le chat à la fin d'une session",
                    subtitle: "Lance automatiquement la vidéo en plein écran",
                    isOn: $preferences.autoPlayCatVideo
                )
                Divider().overlay(Theme.stroke)
                ToggleRow(
                    title: "Son de la vidéo",
                    subtitle: "Active le son du chat quand la vidéo se lance",
                    isOn: $preferences.catVideoSoundEnabled
                )
                Divider().overlay(Theme.stroke)
                ToggleRow(
                    title: "Démarrer la phase suivante automatiquement",
                    subtitle: "Enchaîne focus et pauses sans cliquer",
                    isOn: $preferences.autoStartNextPhase
                )
            }
        }
    }

    // MARK: - Cat library

    private var catLibrarySection: some View {
        SettingsSection(
            title: "Chat affiché à la fin",
            trailing: AnyView(
                Text("\(cats.count) disponible\(cats.count > 1 ? "s" : "")")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            )
        ) {
            VStack(alignment: .leading, spacing: 14) {
                heroPreview

                if cats.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 200), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(cats) { cat in
                            CatCard(
                                cat: cat,
                                isSelected: selection.current?.id == cat.id
                            ) {
                                selection.select(cat)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var heroPreview: some View {
        let current = selection.current
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.45))

            if let cat = current {
                switch cat.kind {
                case .video:
                    TransparentVideoView(
                        url: cat.url,
                        isMuted: true,
                        gravity: .resizeAspect,
                        loops: true
                    )
                    .padding(16)
                case .animatedImage:
                    AnimatedImageView(url: cat.url)
                        .padding(16)
                }
            } else {
                VStack(spacing: 10) {
                    Text("🐱")
                        .font(.system(size: 70))
                    Text("Aucun chat sélectionné")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(height: 260)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("Aucun chat trouvé")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Layout helpers

private struct SettingsSection<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                trailing
            }
            SettingsCard { content() }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Duration row (slider + value + reset)

private struct DurationRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let defaultValue: Int
    var unit: String = "min"
    let accent: LinearGradient
    let resetAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 180, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .controlSize(.small)
            .tint(Color(red: 1.00, green: 0.45, blue: 0.40))

            HStack(spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(width: 70, alignment: .trailing)

            ResetButton(disabled: value == defaultValue, action: resetAction)
        }
    }
}

private struct ResetButton: View {
    let disabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
                .foregroundStyle(disabled ? Theme.textTertiary : Theme.textSecondary)
                .background(
                    Circle().fill(hovering && !disabled ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
                )
                .overlay(
                    Circle().stroke(Theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering = $0 }
        .help("Réinitialiser")
    }
}

// MARK: - Toggle row

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color(red: 1.00, green: 0.45, blue: 0.40))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Cat card

private struct CatCard: View {
    let cat: Cat
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                        .aspectRatio(16/10, contentMode: .fit)

                    Group {
                        switch cat.kind {
                        case .video:
                            TransparentVideoView(
                                url: cat.url,
                                isMuted: true,
                                gravity: .resizeAspect,
                                loops: true
                            )
                        case .animatedImage:
                            AnimatedImageView(url: cat.url)
                        }
                    }
                    .padding(8)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack(spacing: 6) {
                    Text(cat.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer(minLength: 4)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accentGradient)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderStyle, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(hovering ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var borderStyle: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(Theme.accentGradient) }
        return AnyShapeStyle(Theme.stroke)
    }
}
