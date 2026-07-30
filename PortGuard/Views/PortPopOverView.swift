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
