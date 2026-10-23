import SwiftUI

public struct PortPopOverView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.openWindow) private var openWindow

    @State private var lastCount: Int
    @State private var isCelebrating = false
    @State private var sloganIndex = 0

    // Calm slogan rotation: once every 20 seconds.
    @State private var sloganTimer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    public init(engine: PortMonitorEngine) {
        self.engine = engine
        _lastCount = State(initialValue: engine.activeProcesses.count)
    }

    private var lang: String { engine.appLanguage }

    private var hasAlert: Bool {
        !engine.activeViolations.isEmpty || engine.portConflictProcess != nil
    }

    private var guardMood: GuardMood {
        if hasAlert { return .alert }
        if isCelebrating { return .happy }
        if engine.activeProcesses.isEmpty { return .sleepy }
        return .idle
    }

    private var sloganKeys: [String] {
        if hasAlert { return ["Dikkat! Kural ihlali", "Bir şeyler ters gidiyor!"] }
        if isCelebrating { return ["Yeni bir port geldi, hoş geldin!"] }
        if engine.activeProcesses.isEmpty { return ["Zzz... portlar sakin", "Sessiz bir gün, şekerleme vakti"] }
        return ["Her şey yolunda!", "Portlar benden sorulur", "Nöbetteyim, içiniz rahat olsun"]
    }

    private var slogan: String {
        let keys = sloganKeys
        return keys[sloganIndex % keys.count].localized(language: lang)
    }

    private var totalCPU: Double {
        engine.activeProcesses.reduce(0.0) { $0 + $1.cpuPercent }
    }

    private var emptyMood: GuardMood { engine.activeProcesses.isEmpty ? .sleepy : .idle }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    GuardMascot(mood: guardMood, size: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PortGuard")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppleTheme.label)
                        Text(slogan)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(hasAlert ? AppleTheme.accentRed : AppleTheme.secondaryLabel)
                            .lineLimit(1)
                            .id(slogan)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.35), value: slogan)
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
                VStack(spacing: 6) {
                    GuardMascot(mood: emptyMood, size: 96)
                    Text("Aktif Dev Portu Bulunmadı".localized(language: lang))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppleTheme.label)
                    Text((engine.activeProcesses.isEmpty
                          ? "Portlar sakin, Guard şekerleme yapıyor"
                          : "Aramana veya filtrene uyan port yok").localized(language: lang))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 170)
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
                .help("Dashboard Penceresini Aç".localized(language: lang))

                Button("Çıkış".localized(language: lang)) {
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
        .onReceive(sloganTimer) { _ in sloganIndex += 1 }
        .onChange(of: engine.activeProcesses.count) { newValue in
            if lastCount == 0 && newValue > 0 {
                isCelebrating = true
                sloganIndex = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { isCelebrating = false }
            }
            lastCount = newValue
        }
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
