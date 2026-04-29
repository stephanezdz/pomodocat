import SwiftUI
import Combine

enum SessionPhase: String {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Pause courte"
        case .longBreak: return "Pause longue"
        }
    }

    var subtitle: String {
        switch self {
        case .focus: return "Concentre-toi, le chat veille"
        case .shortBreak: return "Respire un peu"
        case .longBreak: return "Tu l'as bien mérité"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .focus: return Theme.focusGradient
        case .shortBreak: return Theme.breakGradient
        case .longBreak: return Theme.longBreakGradient
        }
    }

    @MainActor
    func durationSeconds(prefs: Preferences) -> Int {
        switch self {
        case .focus:      return prefs.focusMinutes * 60
        case .shortBreak: return prefs.shortBreakMinutes * 60
        case .longBreak:  return prefs.longBreakMinutes * 60
        }
    }
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: SessionPhase = .focus
    @Published private(set) var remaining: Int
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var completedFocusSessions: Int = 0

    private var totalDuration: Int
    private var timer: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    private let prefs: Preferences

    var onPhaseFinished: ((SessionPhase) -> Void)?

    init(preferences: Preferences) {
        self.prefs = preferences
        let initial = SessionPhase.focus.durationSeconds(prefs: preferences)
        self.totalDuration = initial
        self.remaining = initial

        // When the user changes durations in Settings while we're not running,
        // reflect the new value in the visible time.
        prefs.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.applyPrefsIfIdle() }
            }
            .store(in: &cancellables)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - Double(remaining) / Double(totalDuration)
    }

    var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        pause()
        remaining = totalDuration
    }

    func skip() {
        finishCurrentPhase(triggerOverlay: false)
    }

    private func tick() {
        guard remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 {
            finishCurrentPhase(triggerOverlay: true)
        }
    }

    private func finishCurrentPhase(triggerOverlay: Bool) {
        pause()
        let finishedPhase = phase
        if finishedPhase == .focus {
            completedFocusSessions += 1
        }

        let next: SessionPhase
        if finishedPhase == .focus {
            next = (completedFocusSessions % prefs.sessionsBeforeLongBreak == 0) ? .longBreak : .shortBreak
        } else {
            next = .focus
        }

        phase = next
        totalDuration = next.durationSeconds(prefs: prefs)
        remaining = totalDuration

        if triggerOverlay && prefs.autoPlayCatVideo {
            onPhaseFinished?(finishedPhase)
        }

        if prefs.autoStartNextPhase {
            start()
        }
    }

    /// Reflect a Preferences change on the visible time when the timer isn't running.
    private func applyPrefsIfIdle() {
        guard !isRunning else { return }
        let newDuration = phase.durationSeconds(prefs: prefs)
        if newDuration != totalDuration {
            totalDuration = newDuration
            remaining = newDuration
        }
    }
}
