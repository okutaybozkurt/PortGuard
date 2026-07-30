import SwiftUI

@main
struct PortGuardApp: App {
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
