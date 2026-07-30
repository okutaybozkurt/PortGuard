import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject var engine: PortMonitorEngine
    @State private var selectedProcessToKill: PortProcess? = nil
    @State private var showKillConfirmation = false
    @State private var showingSettings = false

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header / Toolbar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "shield.tcp.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PortGuard Dashboard")
                            .font(.title3)
                            .bold()
                        Text("macOS Geliştirme Portu ve Kaynak Yöneticisi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        engine.refreshData()
                    }) {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }

                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Label("Ayarlar", systemImage: "gearshape")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Statistics Grid Cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Aktif Portlar",
                    value: "\(engine.activeProcesses.count)",
                    subtitle: engine.filterDevOnly ? "Geliştirici Servisleri" : "Tüm Sistem Portları",
                    iconName: "network",
                    iconColor: Color.blue
                )

                StatCard(
                    title: "Toplam RAM Kullanımı",
                    value: engine.formattedTotalMemory,
                    subtitle: "Aktif süreçlerin toplam bellek tüketimi",
                    iconName: "memorychip",
                    iconColor: Color.orange
                )

                StatCard(
                    title: "En Yüksek Tüketim",
                    value: engine.highestMemoryProcess?.formattedMemory ?? "0 MB",
                    subtitle: engine.highestMemoryProcess != nil ? "\(engine.highestMemoryProcess!.processName) (:\(engine.highestMemoryProcess!.port))" : "Süreç Yok",
                    iconName: "flame.fill",
                    iconColor: Color.red
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Search & Filter Toolbar
            HStack(spacing: 12) {
                // Search Box
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Port (örn: 3000), Süreç (node, python) veya PID...", text: $engine.searchText)
                        .textFieldStyle(.plain)
                    if !engine.searchText.isEmpty {
                        Button(action: { engine.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Sort Picker
                Picker("Sırala:", selection: $engine.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 210)

                // Filter Dev Only Toggle
                Toggle("Sadece Dev", isOn: $engine.filterDevOnly)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider()

            // Main Table / List View
            if engine.filteredProcesses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.7))
                    Text("Çalışan Dev Portu veya Eşleşen Süreç Bulunmadı")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Yeni bir geliştirme sunucusu (node, python, flutter vb.) başlattığınızda burada otomatik görünecektir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(engine.filteredProcesses) { process in
                            DashboardProcessRow(process: process) {
                                selectedProcessToKill = process
                                showKillConfirmation = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }

            Divider()

            // Footer Status Bar
            HStack {
                Text("Son Güncelleme: \(engine.lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Otomatik Yenileme: \(Int(engine.refreshInterval))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .alert(isPresented: $showKillConfirmation) {
            Alert(
                title: Text("Süreci Sonlandır"),
                message: Text("\(selectedProcessToKill?.processName ?? "") (PID: \(selectedProcessToKill?.pid ?? 0), Port: \(selectedProcessToKill?.port ?? 0)) sürecini kill -9 ile sonlandırmak istediğinizden emin misiniz?"),
                primaryButton: .destructive(Text("Sonlandır (Kill)")) {
                    if let process = selectedProcessToKill {
                        engine.killProcess(process)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(10)
    }
}

struct DashboardProcessRow: View {
    let process: PortProcess
    let onKill: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon / Port Box
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 65, height: 46)
                VStack(spacing: 1) {
                    Text("PORT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                    Text("\(process.port)")
                        .font(.system(.subheadline, design: .monospaced))
                        .bold()
                        .foregroundColor(.blue)
                }
            }

            // Process Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(process.processName)
                        .font(.headline)
                        .bold()

                    if process.isDevProcess {
                        Text("DEV")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    Text("PID: \(process.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Kullanıcı: \(process.user)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // CPU & Memory Indicators
            HStack(spacing: 16) {
                // CPU Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedCPU)
                        .font(.title3)
                        .bold()
                        .foregroundColor(process.cpuPercent > 10.0 ? .purple : .primary)
                    Text("CPU Kullanımı")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // RAM Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedMemory)
                        .font(.title3)
                        .bold()
                        .foregroundColor(process.memoryMB >= 1024 ? .red : .primary)
                    Text("RAM Tüketimi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.trailing, 8)

            // Action Button
            Button(action: onKill) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Kill")
                }
                .font(.subheadline)
                .bold()
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Süreci sonlandır (kill -9)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
