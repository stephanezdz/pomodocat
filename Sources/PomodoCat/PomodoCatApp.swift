import SwiftUI
import AppKit

@main
struct PomodoCatApp: App {
    @StateObject private var preferences: Preferences
    @StateObject private var viewModel: TimerViewModel
    @StateObject private var selection: CatSelection
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let prefs = Preferences()
        let sel = CatSelection()
        let vm = TimerViewModel(preferences: prefs)
        vm.onPhaseFinished = { _ in
            CatOverlayController.shared.show(
                cat: sel.current,
                soundEnabled: prefs.catVideoSoundEnabled
            )
        }
        _preferences = StateObject(wrappedValue: prefs)
        _viewModel = StateObject(wrappedValue: vm)
        _selection = StateObject(wrappedValue: sel)
    }

    var body: some Scene {
        WindowGroup("PomodoCat") {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(selection)
                .environmentObject(preferences)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
