import SwiftUI
import AppKit
import AVFoundation
import AVKit
import Combine

// MARK: - Cat library

struct Cat: Identifiable, Hashable {
    enum Kind { case video, animatedImage }
    let id: String          // filename (e.g. "chat_maya.mov")
    let url: URL
    let displayName: String
    let kind: Kind
}

enum CatLibrary {
    private static let videoExts: Set<String> = ["mov", "mp4"]
    private static let imageExts: Set<String> = ["gif", "png"]

    /// User-writable directory where new cats can be dropped without rebuilding.
    /// `~/Library/Application Support/PomodoCat/cats/`
    static var userCatsDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = support.appendingPathComponent("PomodoCat/cats", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Cats discovered in the user folder. Hot-reloadable: just rescan.
    static func allCats() -> [Cat] {
        scan(directoryURL: userCatsDirectory)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private static func scan(directoryURL: URL?) -> [Cat] {
        guard let url = directoryURL,
              let entries = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }
        return entries.compactMap { fileURL in
            let ext = fileURL.pathExtension.lowercased()
            let kind: Cat.Kind?
            if videoExts.contains(ext) { kind = .video }
            else if imageExts.contains(ext) { kind = .animatedImage }
            else { kind = nil }
            guard let kind else { return nil }
            let id = fileURL.lastPathComponent
            return Cat(
                id: id,
                url: fileURL,
                displayName: prettify(fileURL.deletingPathExtension().lastPathComponent),
                kind: kind
            )
        }
    }

    private static func prettify(_ raw: String) -> String {
        let cleaned = raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        return cleaned
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

// MARK: - Selection (persisted)

@MainActor
final class CatSelection: ObservableObject {
    private let storageKey = "PomodoCat.selectedCatID"

    @Published var selectedID: String? {
        didSet { UserDefaults.standard.set(selectedID, forKey: storageKey) }
    }

    /// Bumped whenever the library should be re-scanned. Views observe this to refresh.
    @Published private(set) var refreshToken: Int = 0

    init() {
        self.selectedID = UserDefaults.standard.string(forKey: storageKey)
    }

    var current: Cat? {
        let cats = CatLibrary.allCats()
        if let id = selectedID, let match = cats.first(where: { $0.id == id }) {
            return match
        }
        return cats.first
    }

    func select(_ cat: Cat) {
        selectedID = cat.id
    }

    func refresh() {
        refreshToken &+= 1
    }
}

// MARK: - Transparent looping video

/// AVPlayerLayer-backed view that preserves the alpha channel of HEVC-with-alpha
/// (or ProRes 4444) videos.
struct TransparentVideoView: NSViewRepresentable {
    let url: URL
    var isMuted: Bool = true
    var gravity: AVLayerVideoGravity = .resizeAspect
    var loops: Bool = true

    func makeNSView(context: Context) -> PlayerContainerView {
        PlayerContainerView(url: url, isMuted: isMuted, gravity: gravity, loops: loops)
    }

    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.update(url: url, isMuted: isMuted, gravity: gravity, loops: loops)
    }

    static func dismantleNSView(_ nsView: PlayerContainerView, coordinator: ()) {
        nsView.tearDown()
    }

    final class PlayerContainerView: NSView {
        private var player: AVPlayer
        private let playerLayer = AVPlayerLayer()
        private var loopObserver: NSObjectProtocol?
        private var currentURL: URL
        private var loops: Bool

        init(url: URL, isMuted: Bool, gravity: AVLayerVideoGravity, loops: Bool) {
            let item = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: item)
            self.player.isMuted = isMuted
            self.player.actionAtItemEnd = .none
            self.currentURL = url
            self.loops = loops

            super.init(frame: .zero)

            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
            layerContentsRedrawPolicy = .duringViewResize

            playerLayer.player = player
            playerLayer.backgroundColor = NSColor.clear.cgColor
            playerLayer.videoGravity = gravity
            playerLayer.pixelBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            layer?.addSublayer(playerLayer)

            attachLoopObserver(item: item)
            player.play()
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }

        func update(url: URL, isMuted: Bool, gravity: AVLayerVideoGravity, loops: Bool) {
            self.loops = loops
            playerLayer.videoGravity = gravity
            player.isMuted = isMuted

            if url != currentURL {
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
                currentURL = url
                attachLoopObserver(item: item)
                player.seek(to: .zero)
                player.play()
            }
        }

        private func attachLoopObserver(item: AVPlayerItem) {
            if let obs = loopObserver {
                NotificationCenter.default.removeObserver(obs)
            }
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                if self.loops {
                    self.player.seek(to: .zero)
                    self.player.play()
                }
            }
        }

        func tearDown() {
            player.pause()
            player.replaceCurrentItem(with: nil)
            if let obs = loopObserver {
                NotificationCenter.default.removeObserver(obs)
                loopObserver = nil
            }
        }

        deinit { tearDown() }
    }
}

// MARK: - Animated image (GIF / APNG)

struct AnimatedImageView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        view.canDrawSubviewsIntoLayer = true
        view.image = NSImage(contentsOf: url)
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(contentsOf: url)
    }
}
