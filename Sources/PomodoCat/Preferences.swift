import SwiftUI

@MainActor
final class Preferences: ObservableObject {

    // MARK: Defaults

    enum Defaults {
        static let focusMinutes              = 25
        static let shortBreakMinutes         = 5
        static let longBreakMinutes          = 15
        static let sessionsBeforeLongBreak   = 4
        static let autoPlayCatVideo          = true
        static let catVideoSoundEnabled      = true
        static let autoStartNextPhase        = false
    }

    // MARK: Storage keys

    private enum Keys {
        static let focus     = "Pref.focusMinutes"
        static let shortBrk  = "Pref.shortBreakMinutes"
        static let longBrk   = "Pref.longBreakMinutes"
        static let cycle     = "Pref.sessionsBeforeLongBreak"
        static let autoPlay  = "Pref.autoPlayCatVideo"
        static let catSound  = "Pref.catVideoSoundEnabled"
        static let autoStart = "Pref.autoStartNextPhase"
    }

    // MARK: Allowed ranges

    static let focusRange: ClosedRange<Int>     = 1...60
    static let shortRange: ClosedRange<Int>     = 1...30
    static let longRange: ClosedRange<Int>      = 1...60
    static let cycleRange: ClosedRange<Int>     = 2...8

    // MARK: Published values

    @Published var focusMinutes: Int { didSet { ud.set(focusMinutes, forKey: Keys.focus) } }
    @Published var shortBreakMinutes: Int { didSet { ud.set(shortBreakMinutes, forKey: Keys.shortBrk) } }
    @Published var longBreakMinutes: Int { didSet { ud.set(longBreakMinutes, forKey: Keys.longBrk) } }
    @Published var sessionsBeforeLongBreak: Int { didSet { ud.set(sessionsBeforeLongBreak, forKey: Keys.cycle) } }
    @Published var autoPlayCatVideo: Bool { didSet { ud.set(autoPlayCatVideo, forKey: Keys.autoPlay) } }
    @Published var catVideoSoundEnabled: Bool { didSet { ud.set(catVideoSoundEnabled, forKey: Keys.catSound) } }
    @Published var autoStartNextPhase: Bool { didSet { ud.set(autoStartNextPhase, forKey: Keys.autoStart) } }

    private let ud = UserDefaults.standard

    init() {
        self.focusMinutes            = (ud.object(forKey: Keys.focus) as? Int) ?? Defaults.focusMinutes
        self.shortBreakMinutes       = (ud.object(forKey: Keys.shortBrk) as? Int) ?? Defaults.shortBreakMinutes
        self.longBreakMinutes        = (ud.object(forKey: Keys.longBrk) as? Int) ?? Defaults.longBreakMinutes
        self.sessionsBeforeLongBreak = (ud.object(forKey: Keys.cycle) as? Int) ?? Defaults.sessionsBeforeLongBreak
        self.autoPlayCatVideo        = (ud.object(forKey: Keys.autoPlay) as? Bool) ?? Defaults.autoPlayCatVideo
        self.catVideoSoundEnabled    = (ud.object(forKey: Keys.catSound) as? Bool) ?? Defaults.catVideoSoundEnabled
        self.autoStartNextPhase      = (ud.object(forKey: Keys.autoStart) as? Bool) ?? Defaults.autoStartNextPhase
    }

    // MARK: Reset helpers

    func resetFocus()      { focusMinutes = Defaults.focusMinutes }
    func resetShortBreak() { shortBreakMinutes = Defaults.shortBreakMinutes }
    func resetLongBreak()  { longBreakMinutes = Defaults.longBreakMinutes }
    func resetCycle()      { sessionsBeforeLongBreak = Defaults.sessionsBeforeLongBreak }
}
