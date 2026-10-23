import SwiftUI

public struct PortPopOverView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.openWindow) private var openWindow


    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    private var totalCPU: Double {
        engine.activeProcesses.reduce(0.0) { $0 + $1.cpuPercent }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    PortGuardMarkIcon(size: 18, color: AppleTheme.accentBlue)
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
                    .help("Yenile".localized(language: lang))

                    Button(action: {
                        openWindow(id: "main-dashboard")
                        NSApp.activate(ignoringOtherApps: true)
                    }) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .buttonStyle(.plain)
                    .help("Dashboard Penceresini Aç".localized(language: lang))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .background(AppleTheme.separator)

            // Quick Stats Cards
            HStack(spacing: 6) {
                PopoverStatCard(icon: "network",
                                value: "\(engine.activeProcesses.count)",
                                label: "Aktif Port".localized(language: lang),
                                tint: engine.activeProcesses.isEmpty ? .secondary : AppleTheme.accentGreen)
                PopoverStatCard(icon: "memorychip",
                                value: engine.formattedTotalMemory,
                                label: "Toplam RAM".localized(language: lang),
                                tint: AppleTheme.accentOrange)
                PopoverStatCard(icon: "cpu",
                                value: String(format: "%.1f%%", totalCPU),
                                label: "Toplam CPU".localized(language: lang),
                                tint: AppleTheme.accentPurple)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()
                .background(AppleTheme.separator)

            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .font(.system(size: 11))
                TextField("Port veya süreç adı ara...".localized(language: lang), text: $engine.searchText)
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
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(AppleTheme.secondaryLabel)
                    Text("Aktif Dev Portu Bulunmadı".localized(language: lang))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppleTheme.label)
                    if !engine.activeProcesses.isEmpty {
                        Text("Aramana veya filtrene uyan port yok".localized(language: lang))
                            .font(.system(size: 10))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 170)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(engine.filteredProcesses) { process in
                            PopoverProcessRow(process: process) {
                                engine.requestKill(process, language: lang)
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
                Toggle("Sadece Dev".localized(language: lang), isOn: $engine.filterDevOnly)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))

                Spacer()

                Button(action: {
                    openWindow(id: "main-dashboard")
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    Label("Dashboard".localized(language: lang), systemImage: "macwindow")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(AppleTheme.secondaryLabel)
                .keyboardShortcut("d", modifiers: .command)
                .help("Dashboard Penceresini Aç".localized(language: lang) + " (⌘D)")

                Button("Çıkış".localized(language: lang)) {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.9))
                .keyboardShortcut("q", modifiers: .command)
                .help("\("Çıkış".localized(language: lang)) (⌘Q)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 340)
        .background(.regularMaterial)
        .preferredColorScheme(engine.selectedTheme.colorScheme)
    }
}

private struct PopoverStatCard: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(AppleTheme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AppleTheme.secondaryLabel)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(tint.opacity(0.10))
        .cornerRadius(9)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(tint.opacity(0.18), lineWidth: 0.8))
    }
}
