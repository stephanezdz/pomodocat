import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TimerViewModel
    @EnvironmentObject var catSelection: CatSelection
    @EnvironmentObject var preferences: Preferences
    @State private var selection: SidebarItem = .timer
    @State private var showSplash = true

    var body: some View {
        ZStack {
            mainLayout
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .frame(minWidth: 880, minHeight: 620)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    showSplash = false
                }
            }
        }
    }

    private var mainLayout: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)

            Group {
                switch selection {
                case .timer:
                    TimerView(viewModel: viewModel)
                case .settings:
                    SettingsView(
                        selection: catSelection,
                        preferences: preferences
                    )
                case .sessions, .stats:
                    PlaceholderView(item: selection)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
