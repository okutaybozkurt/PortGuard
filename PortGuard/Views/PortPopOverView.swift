import SwiftUI

public struct PortPopOverView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.openWindow) private var openWindow

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "shield.tcp.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .bold))
                    Text("PortGuard")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        engine.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .buttonStyle(.plain)
                    .help("Yenile")

                    Button(action: {
                        openWindow(id: "main-dashboard")
                        NSApp.activate(ignoringOtherApps: true)
                    }) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .buttonStyle(.plain)
                    .help("Dashboard Penceresini Aç")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .background(AppleTheme.separator)

            // Quick Stats Banner
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(engine.activeProcesses.isEmpty ? Color.secondary : Color.green)
                        .frame(width: 7, height: 7)
                    Text("\(engine.activeProcesses.count) Aktif Port")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text(engine.formattedTotalMemory)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(AppleTheme.label)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))

            Divider()
                .background(AppleTheme.separator)

            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .font(.system(size: 11))
                TextField("Port veya süreç adı ara...", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !engine.searchText.isEmpty {
                    Button(action: { engine.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppleTheme.secondaryLabel)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(NSColor.textBackgroundColor).opacity(0.8))
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(AppleTheme.separator, lineWidth: 0.8)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)

            Divider()
                .background(AppleTheme.separator)

            // Process List View
            if engine.filteredProcesses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.8))
                    Text("Aktif Dev Portu Bulunmadı")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(engine.filteredProcesses) { process in
                            PopoverProcessRow(process: process) {
                                engine.killProcess(process)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 290)
            }

            Divider()
                .background(AppleTheme.separator)

            // Footer Bar
            HStack {
                Toggle("Sadece Dev", isOn: $engine.filterDevOnly)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))

                Spacer()

                Button("Çıkış") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 340)
        .background(.ultraThinMaterial)
        .preferredColorScheme(engine.selectedTheme.colorScheme)
    }
}
