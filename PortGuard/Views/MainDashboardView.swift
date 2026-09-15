import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject var engine: PortMonitorEngine
    @State private var selectedProcessToKill: PortProcess? = nil
    @State private var showKillConfirmation = false
    @State private var showMultiKillConfirmation = false
    @State private var showingSettings = false
    @State private var showingProjectScan = false
    @State private var showingRuleEditor = false
    @State private var selectedProcesses: Set<String> = []
    @State private var selectedTab: DashboardTab = .ports

    public enum DashboardTab: String, CaseIterable, Identifiable {
        case ports   = "Portlar"
        case network = "Ağ Aktivitesi"
        case history = "Geçmiş"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .ports:   return "network"
            case .network: return "antenna.radiowaves.left.and.right"
            case .history: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    public var body: some View {
        VStack(spacing: 0) {
            // Header / Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PortGuard Dashboard")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                    Text("macOS Geliştirme Portu ve Kaynak Yöneticisi".localized(language: lang))
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }

                Spacer()

                HStack(spacing: 8) {
                    if !selectedProcesses.isEmpty && selectedTab == .ports {
                        Button(action: { showMultiKillConfirmation = true }) {
                            Label("\("Seçilenleri Durdur".localized(language: lang)) (\(selectedProcesses.count))", systemImage: "xmark.bin.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }

                    // Özellik 5: Project Scan
                    Button(action: { showingProjectScan = true }) {
                        Label("Proje Tara".localized(language: lang), systemImage: "folder.badge.magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .help("Proje Port Tarayıcı".localized(language: lang))

                    // Özellik 8: Rule Editor
                    Button(action: { showingRuleEditor = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Kurallar".localized(language: lang))
                            if !engine.activeViolations.isEmpty {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .help("Politika Kuralları".localized(language: lang))

                    Button(action: {
                        engine.refreshData()
                        selectedProcesses.removeAll()
                    }) {
                        Label("Yenile".localized(language: lang), systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)

                    Button(action: { showingSettings.toggle() }) {
                        Label("Ayarlar".localized(language: lang), systemImage: "gearshape.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider().background(AppleTheme.separator)

            // Statistics Grid Cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Aktif Portlar".localized(language: lang),
                    value: "\(engine.activeProcesses.count)",
                    subtitle: engine.filterDevOnly
                        ? "Geliştirici Servisleri".localized(language: lang)
                        : "Tüm Sistem Portları".localized(language: lang),
                    iconName: "network",
                    iconColor: Color.blue
                )

                StatCard(
                    title: "Toplam RAM Kullanımı".localized(language: lang),
                    value: engine.formattedTotalMemory,
                    subtitle: "Aktif süreçlerin toplam bellek tüketimi".localized(language: lang),
                    iconName: "memorychip",
                    iconColor: Color.orange
                )

                StatCard(
                    title: "En Yüksek Tüketim".localized(language: lang),
                    value: engine.highestMemoryProcess?.formattedMemory ?? "0 MB",
                    subtitle: engine.highestMemoryProcess != nil
                        ? "\(engine.highestMemoryProcess!.processName) (:\(engine.highestMemoryProcess!.port))"
                        : "Süreç Yok".localized(language: lang),
                    iconName: "flame.fill",
                    iconColor: Color.red
                )

                // Özellik 1: Network stat card
                StatCard(
                    title: "Ağ Bağlantısı".localized(language: lang),
                    value: "\(engine.networkConnections.count)",
                    subtitle: "ESTABLISHED TCP",
                    iconName: "antenna.radiowaves.left.and.right",
                    iconColor: .teal
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Tab picker
            HStack(spacing: 0) {
                ForEach(DashboardTab.allCases) { tab in
                    Button(action: { withAnimation(.appleSpring) { selectedTab = tab } }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.rawValue.localized(language: lang))
                                .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear
                        )
                        .foregroundColor(selectedTab == tab ? .accentColor : AppleTheme.secondaryLabel)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            // Özellik 4: Conflict Banner (only in Ports tab when search is a port number)
            if selectedTab == .ports && engine.searchIsPortQuery {
                ConflictBanner(
                    port: Int(engine.searchText.trimmingCharacters(in: .whitespaces)) ?? 0,
                    conflictProcess: engine.portConflictProcess,
                    language: lang,
                    onKill: engine.portConflictProcess != nil ? {
                        if let proc = engine.portConflictProcess {
                            selectedProcessToKill = proc
                            showKillConfirmation = true
                        }
                    } : nil
                )
                .padding(.bottom, 8)
            }

            // Search & Filter Bar (Ports tab only)
            if selectedTab == .ports {
                searchFilterBar
            }

            Divider().background(AppleTheme.separator)

            // Tab Content
            Group {
                switch selectedTab {
                case .ports:
                    portsTabContent
                case .network:
                    NetworkActivityView(engine: engine)
                case .history:
                    HistoryView(engine: engine)
                }
            }

            Divider().background(AppleTheme.separator)

            // Footer Status Bar
            HStack {
                Label("\("Son Güncelleme:".localized(language: lang)) \(engine.lastUpdated.formatted(date: .omitted, time: .standard))", systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)

                Spacer()

                // Özellik 8: Active violations indicator
                if !engine.activeViolations.isEmpty {
                    Label("\(engine.activeViolations.count) " + "kural ihlali".localized(language: lang), systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                }

                Label("\("Otomatik Yenileme:".localized(language: lang)) \(Int(engine.refreshInterval))s", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(.thinMaterial)
        }
        .frame(minWidth: 800, minHeight: 560)
        .background(.regularMaterial)
        .preferredColorScheme(engine.selectedTheme.colorScheme)
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .sheet(isPresented: $showingProjectScan) {
            ProjectScanView(engine: engine)
        }
        .sheet(isPresented: $showingRuleEditor) {
            RuleEditorView(engine: engine)
        }
        .alert(isPresented: $showKillConfirmation) {
            let processName = selectedProcessToKill?.processName ?? ""
            let pid = selectedProcessToKill?.pid ?? 0
            let port = selectedProcessToKill?.port ?? 0
            let messageText = "\(processName) (PID: \(pid), Port: \(port)) \("Süreci Durdur".localized(language: lang))?"

            return Alert(
                title: Text("Süreci Durdur".localized(language: lang)),
                message: Text(messageText),
                primaryButton: .destructive(Text("Durdur".localized(language: lang))) {
                    if let process = selectedProcessToKill {
                        engine.killProcess(process)
                        selectedProcesses.remove(process.id)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç".localized(language: lang)))
            )
        }
        .alert(isPresented: $showMultiKillConfirmation) {
            let selectedCount = selectedProcesses.count
            let selectedNames = Set(engine.activeProcesses.filter { selectedProcesses.contains($0.id) }.map { $0.processName })
            var messageText = "\("Seçili Süreçleri Durdur".localized(language: lang)) (\(selectedCount))?"
            if !selectedNames.isEmpty {
                messageText += "\n\n\(selectedNames.joined(separator: ", "))"
            }

            return Alert(
                title: Text("Seçili Süreçleri Durdur".localized(language: lang)),
                message: Text(messageText),
                primaryButton: .destructive(Text("Durdur".localized(language: lang))) {
                    engine.killProcesses(selectedProcesses)
                    selectedProcesses.removeAll()
                },
                secondaryButton: .cancel(Text("Vazgeç".localized(language: lang)))
            )
        }
    }

    // MARK: - Sub-views

    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .font(.system(size: 12))
                TextField("Port (3000), Süreç (node, python) veya PID...".localized(language: lang), text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !engine.searchText.isEmpty {
                    Button(action: { engine.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppleTheme.secondaryLabel)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppleTheme.separator, lineWidth: 0.8))

            Picker("Sırala:".localized(language: lang), selection: $engine.sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue.localized(language: lang)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 12))
            .frame(width: 210)

            Toggle("Sadece Dev".localized(language: lang), isOn: $engine.filterDevOnly)
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var portsTabContent: some View {
        if engine.filteredProcesses.isEmpty && engine.ghostPinnedPorts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "shield.checkmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green.opacity(0.8))
                Text("Çalışan Dev Portu veya Eşleşen Süreç Bulunmadı".localized(language: lang))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppleTheme.label)
                Text("Yeni bir geliştirme sunucusu (node, python, flutter vb.) başlattığınızda burada otomatik görünecektir.".localized(language: lang))
                    .font(.system(size: 12))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Özellik 2: Ghost rows for pinned-but-inactive ports
                    ForEach(engine.ghostPinnedPorts, id: \.self) { port in
                        GhostPortRow(port: port, language: lang) {
                            engine.togglePin(port: port)
                        }
                    }

                    ForEach(engine.filteredProcesses) { process in
                        let isSelectedBinding = Binding<Bool>(
                            get: { selectedProcesses.contains(process.id) },
                            set: { isSelected in
                                if isSelected { selectedProcesses.insert(process.id) }
                                else { selectedProcesses.remove(process.id) }
                            }
                        )

                        DashboardProcessRow(process: process, isSelected: isSelectedBinding) {
                            selectedProcessToKill = process
                            showKillConfirmation = true
                        }
                        // Özellik 2: Pin context menu
                        .contextMenu {
                            Button(action: { engine.togglePin(port: process.port) }) {
                                Label(
                                    (engine.pinnedPorts.contains(process.port) ? "Pini Kaldır" : "Pinle").localized(language: lang),
                                    systemImage: engine.pinnedPorts.contains(process.port) ? "pin.slash" : "pin.fill"
                                )
                            }
                            Divider()
                            if process.isKillable {
                                Button(role: .destructive, action: {
                                    selectedProcessToKill = process
                                    showKillConfirmation = true
                                }) {
                                    Label("Sonlandır".localized(language: lang), systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
    }
}
