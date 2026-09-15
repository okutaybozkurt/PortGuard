import SwiftUI

/// Özellik 1 — ESTABLISHED Connections (Ağ Aktivitesi Sekmesi)
/// Shows all active TCP connections grouped by process name.
/// Data is real-time from `lsof -iTCP -P -n`.
public struct NetworkActivityView: View {
    @ObservedObject var engine: PortMonitorEngine
    @State private var searchText: String = ""
    @State private var groupByProcess: Bool = true
    @State private var showLocalPortInfo: Bool = false
    @State private var showEstablishedInfo: Bool = false
    @State private var showStateInfo: Bool = false

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    // MARK: - Filtered connections

    private var filtered: [NetworkConnection] {
        let all = engine.networkConnections
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let q = searchText.lowercased()
        return all.filter {
            $0.processName.lowercased().contains(q) ||
            $0.remoteAddress.lowercased().contains(q) ||
            "\($0.remotePort)".contains(q) ||
            "\($0.localPort)".contains(q)
        }
    }

    private var grouped: [String: [NetworkConnection]] {
        Dictionary(grouping: filtered, by: \.processName)
    }

    private var sortedGroupKeys: [String] {
        grouped.keys.sorted { a, b in
            (grouped[b]?.count ?? 0) < (grouped[a]?.count ?? 0)
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Info banner
            infoBanner

            // Toolbar
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppleTheme.secondaryLabel)
                        .font(.system(size: 12))
                    TextField("Süreç, IP veya port ara…".localized(language: lang), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
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

                Toggle("Süreç Bazlı".localized(language: lang), isOn: $groupByProcess)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .medium))

                Spacer()

                // Refresh
                Button(action: { engine.refreshData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .help("Bağlantıları Yenile".localized(language: lang))

                // Badge
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.7), radius: 3)
                    Text("\(filtered.count) " + "bağlantı".localized(language: lang))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider().background(AppleTheme.separator)

            if filtered.isEmpty {
                emptyStateView
            } else if groupByProcess {
                groupedListView
            } else {
                flatListView
            }
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Info box 1: Yerel Port
                InfoBox(
                    icon: "arrow.left.arrow.right",
                    iconColor: .blue,
                    title: "Yerel Port Nedir?".localized(language: lang),
                    isExpanded: $showLocalPortInfo
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bir uygulama internete bağlanmak istediğinde macOS ona **geçici (ephemeral) bir yerel port** atar.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.label)
                        Text("Örnek: Chrome bir web sitesine bağlanırken **53613** gibi yüksek numaralı bir port kullanır. Bu port, **taraftaki kapıdır** — bağlantı bitince kapanır.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.secondaryLabel)
                        HStack(spacing: 6) {
                            Text("Yerel Port: 53613".localized(language: lang))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1)).cornerRadius(6)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundColor(AppleTheme.secondaryLabel)
                            Text("Uzak Port: 443 (HTTPS)".localized(language: lang))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.orange.opacity(0.1)).cornerRadius(6)
                        }
                    }
                }

                // Info box 2: ESTABLISHED
                InfoBox(
                    icon: "checkmark.seal.fill",
                    iconColor: .green,
                    title: "ESTABLISHED Ne Demek?".localized(language: lang),
                    isExpanded: $showEstablishedInfo
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TCP bağlantısının **3'lü el sıkışması (handshake) tamamlanmış** ve veri alışverişi aktif olarak devam ediyor demektir.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.label)
                        Text("**Pratik örnekler:** Açık bir browser sekmesi, veritabanı bağlantısı, Slack sync, GitHub API isteği — hepsi ESTABLISHED görünür.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                }

                // Info box 3: Durumlar
                InfoBox(
                    icon: "info.circle.fill",
                    iconColor: .purple,
                    title: "Bağlantı Durumları".localized(language: lang),
                    isExpanded: $showStateInfo
                ) {
                    VStack(alignment: .leading, spacing: 5) {
                        StateRow(color: .green,  state: "ESTABLISHED", desc: "Aktif — veri alışverişi sürüyor".localized(language: lang))
                        StateRow(color: .orange, state: "CLOSE_WAIT",  desc: "Karşı taraf kapattı, bekleniyor".localized(language: lang))
                        StateRow(color: .yellow, state: "TIME_WAIT",   desc: "Kapanıyor — son paketler bekleniyor".localized(language: lang))
                        StateRow(color: .blue,   state: "SYN_SENT",    desc: "Bağlantı kurulmaya çalışılıyor".localized(language: lang))
                        StateRow(color: .gray,   state: "DIĞER",       desc: "Farklı geçiş durumları".localized(language: lang))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))

            Divider().background(AppleTheme.separator)
        }
    }

    // MARK: - List views

    private var groupedListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(sortedGroupKeys, id: \.self) { processName in
                    let connections = grouped[processName] ?? []
                    NetworkProcessGroup(processName: processName, connections: connections, language: lang)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private var flatListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filtered) { conn in
                    NetworkConnectionRow(connection: conn, language: lang)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "network.slash")
                .font(.system(size: 48))
                .foregroundColor(AppleTheme.secondaryLabel.opacity(0.5))
            Text("Aktif TCP Bağlantısı Bulunamadı".localized(language: lang))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppleTheme.label)
            Text("Bir tarayıcı, API istemcisi veya veritabanı bağlantısı açıldığında burada otomatik görünür.".localized(language: lang))
                .font(.system(size: 12))
                .foregroundColor(AppleTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - InfoBox

private struct InfoBox<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.appleSpring) { isExpanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppleTheme.label)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(iconColor.opacity(0.2), lineWidth: 0.8))
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(10)
                    .background(iconColor.opacity(0.04))
                    .cornerRadius(8)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - State Row (for legend)

private struct StateRow: View {
    let color: Color
    let state: String
    let desc: String

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(state)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(AppleTheme.label)
                .frame(width: 100, alignment: .leading)
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(AppleTheme.secondaryLabel)
        }
    }
}

// MARK: - Network Process Group

private struct NetworkProcessGroup: View {
    let processName: String
    let connections: [NetworkConnection]
    let language: String
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.appleSpring) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppleTheme.secondaryLabel)

                    Text(processName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppleTheme.label)

                    Text("\(connections.count)")
                        .appleBadgeStyle(color: .blue)

                    Spacer()

                    let established = connections.filter { $0.state == .established }.count
                    if established > 0 {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("\(established) " + "aktif".localized(language: language))
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppleTheme.separator, lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(connections) { conn in
                        NetworkConnectionRow(connection: conn, language: language)
                            .padding(.leading, 14)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Network Connection Row

private struct NetworkConnectionRow: View {
    let connection: NetworkConnection
    let language: String
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // State dot
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
                .shadow(color: stateColor.opacity(0.6), radius: 3)

            // Yerel port (ephemeral)
            VStack(alignment: .leading, spacing: 1) {
                Text("Yerel".localized(language: language))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppleTheme.tertiaryLabel)
                Text(verbatim: ":\(connection.localPort)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }
            .frame(width: 62, alignment: .leading)
            .help("Yerel (ephemeral) port — bu bilgisayarın bağlantı için açtığı geçici port".localized(language: language))

            Image(systemName: "arrow.right")
                .font(.system(size: 9))
                .foregroundColor(AppleTheme.secondaryLabel)

            // Remote endpoint
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(connection.remoteAddress)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppleTheme.label)
                        .lineLimit(1)
                    Text(verbatim: ":\(connection.remotePort)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .help("Uzak sunucunun portu — örn. 443 = HTTPS, 80 = HTTP, 5432 = PostgreSQL".localized(language: language))
                }
                HStack(spacing: 6) {
                    Text("PID \(connection.pid)")
                        .font(.system(size: 10))
                        .foregroundColor(AppleTheme.secondaryLabel)
                    if let desc = connection.remotePortDescription {
                        Text(desc)
                            .appleBadgeStyle(color: .teal)
                    }
                }
            }

            Spacer()

            // State badge
            Text(connection.state.displayName)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(stateColor.opacity(0.12))
                .foregroundColor(stateColor)
                .cornerRadius(6)
                .help(stateTip)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .appleCardStyle(hovered: isHovered)
        .onHover { hovering in
            withAnimation(.appleSpring) { isHovered = hovering }
        }
    }

    private var stateColor: Color {
        switch connection.state {
        case .established: return .green
        case .closeWait:   return .orange
        case .timeWait:    return .yellow
        case .synSent:     return .blue
        case .unknown:     return .gray
        }
    }

    private var stateTip: String {
        switch connection.state {
        case .established: return "ESTABLISHED: Veri alışverişi aktif".localized(language: language)
        case .closeWait:   return "CLOSE_WAIT: Karşı taraf kapandı, bu taraf kapatılmayı bekliyor".localized(language: language)
        case .timeWait:    return "TIME_WAIT: Bağlantı kapanıyor, son paketler bekleniyor".localized(language: language)
        case .synSent:     return "SYN_SENT: Bağlantı kurulmaya çalışılıyor".localized(language: language)
        case .unknown:     return "Farklı bir TCP geçiş durumu".localized(language: language)
        }
    }
}
