import SwiftUI
import AppKit

/// SwiftUI, `MenuBarExtra` ile aynı App'te bir `WindowGroup` olduğunda pencereyi
/// launch anında otomatik açmıyor — Spotlight/Dock'tan başlatınca kullanıcı menü
/// çubuğu simgesine tıklamadan hiçbir şey görmüyordu. Launch ve Dock reopen'da
/// pencereyi burada elle öne getiriyoruz.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        bringDashboardToFront()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            bringDashboardToFront()
        }
        return true
    }

    private func bringDashboardToFront(remainingAttempts: Int = 20) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        } else if remainingAttempts > 0 {
            // WindowGroup penceresi henüz kurulmamış olabilir — kısa bir süre
            // sonra tekrar dene (en fazla ~1 saniye, sonsuz döngüye girmesin).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.bringDashboardToFront(remainingAttempts: remainingAttempts - 1)
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
            HStack(spacing: 4) {
                Image(nsImage: .portGuardMenuBarMark(pointSize: 16))
                if !monitorEngine.activeProcesses.isEmpty {
                    Text(verbatim: "\(monitorEngine.activeProcesses.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
            }
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
