import SwiftUI
import AppKit

/// `WindowGroup(id:)` bir "şablon" — SwiftUI onu launch anında OTOMATİK açmıyor,
/// yalnızca `openWindow(id:)` çağrıldığında bir pencere örneği yaratıyor. Ama
/// `openWindow` bir Environment değeri, `AppDelegate` gibi View olmayan bir
/// yerden erişilemiyor. Menü çubuğu etiketi (her zaman launch'ta render edilen
/// tek View) bu action'ı burada yakalayıp köprülüyor.
final class WindowOpener {
    static let shared = WindowOpener()
    var openMainDashboard: (() -> Void)?
}

/// Launch ve Dock reopen'da dashboard penceresini açar/öne getirir. Önce zaten
/// açık bir pencere var mı diye bakar (reopen'da duplicate pencere yaratmamak
/// için), yoksa `WindowOpener` köprüsü hazır olana kadar kısa aralıklarla
/// dener (en fazla ~2 saniye, sonsuz döngüye girmesin).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("PGDEBUG applicationDidFinishLaunching")
        openDashboard()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openDashboard()
        }
        return true
    }

    private func openDashboard(remainingAttempts: Int = 40) {
        NSApp.activate(ignoringOtherApps: true)
        NSLog("PGDEBUG openDashboard attempt, remaining=\(remainingAttempts), windows=\(NSApp.windows.count), hasOpener=\(WindowOpener.shared.openMainDashboard != nil)")

        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            NSLog("PGDEBUG found keyable window, ordering front")
            window.makeKeyAndOrderFront(nil)
            return
        }

        if let open = WindowOpener.shared.openMainDashboard {
            NSLog("PGDEBUG calling openWindow bridge")
            open()
            return
        }

        if remainingAttempts > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.openDashboard(remainingAttempts: remainingAttempts - 1)
            }
        } else {
            NSLog("PGDEBUG gave up, no opener ever appeared")
        }
    }
}

private struct MenuBarLabel: View {
    let activeCount: Int
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: .portGuardMenuBarMark(pointSize: 16))
            if activeCount > 0 {
                Text(verbatim: "\(activeCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
        }
        .onAppear {
            NSLog("PGDEBUG MenuBarLabel onAppear — registering opener")
            WindowOpener.shared.openMainDashboard = {
                NSLog("PGDEBUG openWindow(id: main-dashboard) invoked")
                openWindow(id: "main-dashboard")
            }
        }
    }
}

@main
struct PortGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitorEngine = PortMonitorEngine()

    var body: some Scene {
        // MenuBar Scene
        MenuBarExtra {
            PortPopOverView(engine: monitorEngine)
        } label: {
            MenuBarLabel(activeCount: monitorEngine.activeProcesses.count)
        }
        .menuBarExtraStyle(.window)

        // Main Window Scene
        WindowGroup(id: "main-dashboard") {
            MainDashboardView(engine: monitorEngine)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
