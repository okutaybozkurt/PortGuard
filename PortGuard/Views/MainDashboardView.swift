import SwiftUI

public struct MainDashboardView: View {
    @ObservedObject var engine: PortMonitorEngine
    @State private var selectedProcessToKill: PortProcess? = nil
    @State private var showKillConfirmation = false
    @State private var showMultiKillConfirmation = false
    @State private var showingSettings = false
    @State private var selectedProcesses: Set<String> = []

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
                    Text("macOS Geliştirme Portu ve Kaynak Yöneticisi".localized(language: engine.appLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }

                Spacer()

                HStack(spacing: 10) {
                    if !selectedProcesses.isEmpty {
                        Button(action: {
                            showMultiKillConfirmation = true
                        }) {
                            Label("\("Seçilenleri Durdur".localized(language: engine.appLanguage)) (\(selectedProcesses.count))", systemImage: "xmark.bin.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }

                    Button(action: {
                        engine.refreshData()
                        selectedProcesses.removeAll()
                    }) {
                        Label("Yenile".localized(language: engine.appLanguage), systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Label("Ayarlar".localized(language: engine.appLanguage), systemImage: "gearshape.fill")
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
                    title: "Aktif Portlar".localized(language: engine.appLanguage),
                    value: "\(engine.activeProcesses.count)",
                    subtitle: engine.filterDevOnly ? "Geliştirici Servisleri".localized(language: engine.appLanguage) : "Tüm Sistem Portları".localized(language: engine.appLanguage),
                    iconName: "network",
                    iconColor: Color.blue
                )

                StatCard(
                    title: "Toplam RAM Kullanımı".localized(language: engine.appLanguage),
                    value: engine.formattedTotalMemory,
                    subtitle: "Aktif süreçlerin toplam bellek tüketimi".localized(language: engine.appLanguage),
                    iconName: "memorychip",
                    iconColor: Color.orange
                )

                StatCard(
                    title: "En Yüksek Tüketim".localized(language: engine.appLanguage),
                    value: engine.highestMemoryProcess?.formattedMemory ?? "0 MB",
                    subtitle: engine.highestMemoryProcess != nil ? "\(engine.highestMemoryProcess!.processName) (:\(engine.highestMemoryProcess!.port))" : "Süreç Yok".localized(language: engine.appLanguage),
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
                    TextField("Port (3000), Süreç (node, python) veya PID...".localized(language: engine.appLanguage), text: $engine.searchText)
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
                Picker("Sırala:".localized(language: engine.appLanguage), selection: $engine.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue.localized(language: engine.appLanguage)).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 12))
                .frame(width: 210)

                // Filter Dev Only Toggle
                Toggle("Sadece Dev".localized(language: engine.appLanguage), isOn: $engine.filterDevOnly)
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
                    Text("Çalışan Dev Portu veya Eşleşen Süreç Bulunmadı".localized(language: engine.appLanguage))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppleTheme.label)
                    Text("Yeni bir geliştirme sunucusu (node, python, flutter vb.) başlattığınızda burada otomatik görünecektir.".localized(language: engine.appLanguage))
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
                            let isSelectedBinding = Binding<Bool>(
                                get: { selectedProcesses.contains(process.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedProcesses.insert(process.id)
                                    } else {
                                        selectedProcesses.remove(process.id)
                                    }
                                }
                            )

                            DashboardProcessRow(process: process, isSelected: isSelectedBinding) {
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
                Label("\("Son Güncelleme:".localized(language: engine.appLanguage)) \(engine.lastUpdated.formatted(date: .omitted, time: .standard))", systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)

                Spacer()

                Label("\("Otomatik Yenileme:".localized(language: engine.appLanguage)) \(Int(engine.refreshInterval))s", systemImage: "arrow.triangle.2.circlepath")
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
            let processName = selectedProcessToKill?.processName ?? ""
            let pid = selectedProcessToKill?.pid ?? 0
            let port = selectedProcessToKill?.port ?? 0
            
            let messageText = "\(processName) (PID: \(pid), Port: \(port)) \("Süreci Durdur".localized(language: engine.appLanguage))?"
            
            return Alert(
                title: Text("Süreci Durdur".localized(language: engine.appLanguage)),
                message: Text(messageText),
                primaryButton: .destructive(Text("Durdur".localized(language: engine.appLanguage))) {
                    if let process = selectedProcessToKill {
                        engine.killProcess(process)
                        selectedProcesses.remove(process.id)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç".localized(language: engine.appLanguage)))
            )
        }
        .alert(isPresented: $showMultiKillConfirmation) {
            let selectedCount = selectedProcesses.count
            // Sadece seçili olan süreçlerin isimlerini benzersiz bir şekilde alalım
            let selectedNames = Set(engine.activeProcesses.filter { selectedProcesses.contains($0.id) }.map { $0.processName })
            
            var messageText = "\("Seçili Süreçleri Durdur".localized(language: engine.appLanguage)) (\(selectedCount))?"
            
            if !selectedNames.isEmpty {
                messageText += "\n\n\(selectedNames.joined(separator: ", "))"
            }
            
            return Alert(
                title: Text("Seçili Süreçleri Durdur".localized(language: engine.appLanguage)),
                message: Text(messageText),
                primaryButton: .destructive(Text("Durdur".localized(language: engine.appLanguage))) {
                    engine.killProcesses(selectedProcesses)
                    selectedProcesses.removeAll()
                },
                secondaryButton: .cancel(Text("Vazgeç".localized(language: engine.appLanguage)))
            )
        }
    }
}
