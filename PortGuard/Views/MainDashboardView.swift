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
                VStack(alignment: .leading, spacing: 2) {
                    Text("PortGuard Dashboard")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                    Text("macOS Geliştirme Portu ve Kaynak Yöneticisi")
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        engine.refreshData()
                    }) {
                        Label("Yenile", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider()
                .background(AppleTheme.separator)

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
            .padding(.vertical, 16)

            // Search & Filter Bar
            HStack(spacing: 12) {
                // Search Box
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppleTheme.secondaryLabel)
                        .font(.system(size: 12))
                    TextField("Port (3000), Süreç (node, python) veya PID...", text: $engine.searchText)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppleTheme.separator, lineWidth: 0.8)
                )

                // Sort Picker
                Picker("Sırala:", selection: $engine.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 12))
                .frame(width: 210)

                // Filter Dev Only Toggle
                Toggle("Sadece Dev", isOn: $engine.filterDevOnly)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Divider()
                .background(AppleTheme.separator)

            // Process Table / Scroll Area
            if engine.filteredProcesses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.8))
                    Text("Çalışan Dev Portu veya Eşleşen Süreç Bulunmadı")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppleTheme.label)
                    Text("Yeni bir geliştirme sunucusu (node, python, flutter vb.) başlattığınızda burada otomatik görünecektir.")
                        .font(.system(size: 12))
                        .foregroundColor(AppleTheme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
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
                    .padding(.vertical, 14)
                }
            }

            Divider()
                .background(AppleTheme.separator)

            // Footer Status Bar
            HStack {
                Label("Son Güncelleme: \(engine.lastUpdated.formatted(date: .omitted, time: .standard))", systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)

                Spacer()

                Label("Otomatik Yenileme: \(Int(engine.refreshInterval))s", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(.thinMaterial)
        }
        .frame(minWidth: 760, minHeight: 520)
        .background(.regularMaterial)
        .preferredColorScheme(engine.selectedTheme.colorScheme)
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .alert(isPresented: $showKillConfirmation) {
            Alert(
                title: Text("Süreci Durdur"),
                message: Text("\(selectedProcessToKill?.processName ?? "") (PID: \(selectedProcessToKill?.pid ?? 0), Port: \(selectedProcessToKill?.port ?? 0)) sürecini durdurmak istediğinizden emin misiniz?"),
                primaryButton: .destructive(Text("Durdur")) {
                    if let process = selectedProcessToKill {
                        engine.killProcess(process)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
    }
}
