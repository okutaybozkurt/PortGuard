import AppKit
import SwiftUI
import Combine

private final class QuickSearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// ⌥⌘P ile açılan Spotlight benzeri palet. Esc veya odak kaybında kapanır.
public final class QuickSearchPanelController: ObservableObject {
    public static let shared = QuickSearchPanelController()
    public static let enabledDefaultsKey = "quickSearchEnabled"

    /// ⌥⌘P başka bir uygulama tarafından kullanıldığı için kaydedilemediyse true.
    @Published public private(set) var hotKeyRegistrationFailed = false
    private weak var engine: PortMonitorEngine?
    private var hotKey: GlobalHotKey?
    private var panel: NSPanel?
    private let model = QuickSearchModel()
    private var keyMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var cancellable: AnyCancellable?

    private init() {}

    public var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledDefaultsKey) as? Bool ?? true
    }

    public func start(engine: PortMonitorEngine) {
        self.engine = engine
        applyPreference()
    }

    public func applyPreference() {
        if isEnabled {
            if hotKey == nil { hotKey = GlobalHotKey { [weak self] in self?.toggle() } }
            hotKeyRegistrationFailed = !(hotKey?.register() ?? false)
        } else {
            hotKeyRegistrationFailed = false
            hotKey?.unregister()
            hide()
        }
    }

    public func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    private func show() {
        guard isEnabled, let engine = engine else { return }
        let language = engine.appLanguage

        model.query = ""
        model.processes = engine.activeProcesses
        cancellable = engine.$activeProcesses.receive(on: DispatchQueue.main).sink { [weak self] in self?.model.processes = $0 }
        engine.refreshData()

        let hosting = NSHostingView(rootView: QuickSearchView(model: model, language: language))
        let panel = QuickSearchPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 60),
                                     styleMask: [.borderless, .nonactivatingPanel],
                                     backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hosting
        self.panel = panel

        // İçerik büyüdükçe üst kenarı sabit tutarak yeniden boyutlandır.
        let size = hosting.fittingSize
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrame(NSRect(x: f.midX - 280, y: f.midY + f.height * 0.15 - size.height, width: 560, height: size.height), display: true)
        }

        panel.makeKeyAndOrderFront(nil)

        resignObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel, queue: .main) { [weak self] _ in
            self?.hide()
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event, engine: engine, language: language) ?? event
        }
        resizeToFit()
        cancellableResize = model.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] _ in
            DispatchQueue.main.async { self?.resizeToFit() }
        }
    }

    private var cancellableResize: AnyCancellable?

    private func resizeToFit() {
        guard let panel = panel, let hosting = panel.contentView else { return }
        let h = hosting.fittingSize.height
        var frame = panel.frame
        guard abs(frame.height - h) > 0.5 else { return }
        frame.origin.y += frame.height - h
        frame.size.height = h
        panel.setFrame(frame, display: true)
    }

    private func hide() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        if let o = resignObserver { NotificationCenter.default.removeObserver(o); resignObserver = nil }
        cancellable = nil
        cancellableResize = nil
        let p = panel
        panel = nil
        p?.orderOut(nil)
    }

    private func handle(_ event: NSEvent, engine: PortMonitorEngine, language: String) -> NSEvent? {
        switch event.keyCode {
        case 53: // esc
            hide(); return nil
        case 125: // down
            model.move(1); return nil
        case 126: // up
            model.move(-1); return nil
        case 36, 76: // return / enter
            guard let target = model.selected, target.isKillable,
                  QuickSearchLogic.isStillActive(target, in: engine.activeProcesses) else { return nil }
            if event.modifierFlags.contains(.command) {
                hide()
                engine.requestRestart(target, language: language)
            } else if model.pendingKillID == target.id {
                hide()
                engine.killProcess(target)
            } else {
                model.pendingKillID = target.id   // ilk Enter: onay iste
            }
            return nil
        default:
            return event
        }
    }
}
