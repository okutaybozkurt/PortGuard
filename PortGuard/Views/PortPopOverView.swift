import SwiftUI

public struct PortPopOverView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.openWindow) private var openWindow

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.tcp.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("PortGuard")
                        .font(.headline)
                        .bold()
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        engine.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Yenile")

                    Button(action: {
                        openWindow(id: "main-dashboard")
                        NSApp.activate(ignoringOtherApps: true)
                    }) {
                        Image(systemName: "macwindow")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Dashboard Penceresini Aç")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))

            Divider()

            // Quick Stats Banner
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(engine.activeProcesses.isEmpty ? Color.gray : Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(engine.activeProcesses.count) Aktif Port")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(engine.formattedTotalMemory)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("Port veya süreç adı ara...", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !engine.searchText.isEmpty {
                    Button(action: { engine.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            // Process List
            if engine.filteredProcesses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green.opacity(0.8))
                    Text("Aktif Dev Portu Bulunmadı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(engine.filteredProcesses) { process in
                            PopoverProcessRow(process: process) {
                                engine.killProcess(process)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 280)
            }

            Divider()

            // Footer
            HStack {
                Toggle("Sadece Dev", isOn: $engine.filterDevOnly)
                    .toggleStyle(.checkbox)
                    .font(.caption2)

                Spacer()

                Button("Çıkış") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        }
        .frame(width: 340)
    }
}

struct PopoverProcessRow: View {
    let process: PortProcess
    let onKill: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Port Badge
            Text(":\(process.port)")
                .font(.system(.caption, design: .monospaced))
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(4)

            // Process Info
            VStack(alignment: .leading, spacing: 2) {
                Text(process.processName)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("PID: \(process.pid)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if process.cpuPercent > 0.1 {
                        Text("• \(process.formattedCPU)")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }

            Spacer()

            // RAM Badge
            Text(process.formattedMemory)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(process.memoryMB >= 1024 ? Color.red.opacity(0.15) : Color.orange.opacity(0.12))
                .foregroundColor(process.memoryMB >= 1024 ? .red : .orange)
                .cornerRadius(4)

            // Kill Button
            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("\(process.processName) (\(process.port)) sürecini sonlandır")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
