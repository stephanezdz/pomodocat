import SwiftUI
import AppKit
import AVFoundation

@MainActor
final class CatOverlayController {
    static let shared = CatOverlayController()

    private var window: NSWindow?

    /// Shows the chosen cat fullscreen above every UI surface. If `cat` is nil,
    /// falls back to the 🐱 emoji.
    func show(cat: Cat?, soundEnabled: Bool = true) {
        dismiss()

        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false

        let host = NSHostingView(
            rootView: CatOverlayView(
                cat: cat,
                soundEnabled: soundEnabled
            ) { [weak self] in
                self?.dismiss()
            }
        )
        host.frame = screen.frame
        window.contentView = host
        window.setFrame(screen.frame, display: true)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func dismiss() {
        // Drop the contentView so the AVPlayer is torn down (audio stops immediately).
        window?.contentView = nil
        window?.orderOut(nil)
        window = nil
    }
}

private struct CatOverlayView: View {
    let cat: Cat?
    let soundEnabled: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.clear

            if let cat {
                switch cat.kind {
                case .video:
                    TransparentVideoView(
                        url: cat.url,
                        isMuted: !soundEnabled,
                        gravity: .resizeAspectFill,
                        loops: true
                    )
                    .ignoresSafeArea()
                case .animatedImage:
                    AnimatedImageView(url: cat.url)
                        .ignoresSafeArea()
                }
            } else {
                Text("🐱")
                    .font(.system(size: 520))
            }

            // Bottom-center X button — only way to dismiss with the mouse.
            VStack {
                Spacer()
                CloseButton(action: onDismiss)
                    .padding(.bottom, 56)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        // Esc key still dismisses for accessibility.
        .background(KeyEventCatcher(onKey: onDismiss))
    }
}

// MARK: - Close button

private struct CloseButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(.black.opacity(hovering ? 0.75 : 0.55))
                )
                .overlay(
                    Circle().stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
                .scaleEffect(hovering ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Fermer")
    }
}

// MARK: - Esc key

private struct KeyEventCatcher: NSViewRepresentable {
    let onKey: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKey = onKey
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { nsView.window?.makeFirstResponder(nsView) }
    }

    final class KeyView: NSView {
        var onKey: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            // Only Esc dismisses, so other keys don't accidentally close the overlay.
            if event.keyCode == 53 { onKey?() }
        }
    }
}
