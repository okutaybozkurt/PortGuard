import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: PortMonitorEngine
    @StateObject private var updater = UpdateManager.shared
    @Environment(\.dismiss) private var dismiss

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    Text("PortGuard Ayarları".localized(language: lang))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                }

                Spacer()

                Button("Tamam".localized(language: lang)) {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider()
                .background(AppleTheme.separator)

            // Scrollable Responsive Settings Content
            ScrollView {
                VStack(spacing: 20) {
                    // Section 1: Görünüm ve Tema
                    SettingsSectionCard(title: "Görünüm ve Tema".localized(language: lang), icon: "paintbrush.fill", iconColor: .purple) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Theme Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Uygulama Teması".localized(language: lang))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppleTheme.secondaryLabel)

                                Picker("", selection: $engine.selectedTheme) {
                                    ForEach(AppTheme.allCases) { theme in
                                        Text(theme.rawValue.localized(language: lang)).tag(theme)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }

                            Divider()
                                .background(AppleTheme.separator)

                            // Language Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Uygulama Dili".localized(language: lang))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppleTheme.secondaryLabel)

                                Picker("", selection: $engine.appLanguage) {
                                    Text("Türkçe").tag("tr")
                                    Text("English").tag("en")
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }

                            Divider()
                                .background(AppleTheme.separator)

                            // Toggles
                            Toggle(isOn: $engine.showInDock) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dock Üzerinde Göster (Dock Icon)".localized(language: lang))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppleTheme.label)
                                    Text("Kapatıldığında uygulama sadece MenuBar'da aktif kalır.".localized(language: lang))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppleTheme.secondaryLabel)
                                }
                            }
                            .toggleStyle(.checkbox)

                            Toggle(isOn: $engine.filterDevOnly) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sadece Geliştirici Servislerini Filtrele".localized(language: lang))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppleTheme.label)
                                    Text("Sistem servislerini gizleyerek node, python, docker vb. gösterir.".localized(language: lang))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppleTheme.secondaryLabel)
                                }
                            }
                            .toggleStyle(.checkbox)

                            Divider()
                                .background(AppleTheme.separator)

                            // Refresh Interval Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Otomatik Yenileme Sıklığı".localized(language: lang))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppleTheme.label)
                                    Spacer()
                                    Text("\(Int(engine.refreshInterval)) \("saniye".localized(language: lang))")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }

                                Slider(value: $engine.refreshInterval, in: 2...30, step: 1)

                                Text("PortGuard'ın arka planda portları ve kaynakları ne sıklıkla izleyeceğini belirler.".localized(language: lang))
                                    .font(.system(size: 11))
                                    .foregroundColor(AppleTheme.secondaryLabel)
                            }
                        }
                    }

                    // Section 2: Özel Dev Servisi Filtreleri
                    SettingsSectionCard(title: "Özel Dev Servisi Filtreleri".localized(language: lang), icon: "slider.horizontal.3", iconColor: .blue) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ek Özel Süreç İsimleri (virgülle ayırın):".localized(language: lang))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppleTheme.secondaryLabel)

                            TextField("Örn: my-app-service, elixir, beam.smp, custom-tool".localized(language: lang), text: $engine.customDevKeywordsInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))

                            Text("PortGuard varsayılan olarak node, python, docker, dart, java, go, ruby, vite vb. otomatik tanır.".localized(language: lang))
                                .font(.system(size: 11))
                                .foregroundColor(AppleTheme.secondaryLabel)
                        }
                    }

                    // Section 3: RAM ve Bildirim Uyarıları
                    SettingsSectionCard(title: "RAM ve Bildirim Uyarıları".localized(language: lang), icon: "bell.badge.fill", iconColor: .orange) {
                        VStack(alignment: .leading, spacing: 14) {
                            Toggle(isOn: $engine.notificationsEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yüksek RAM Tüketim Bildirimlerini Aktifleştir".localized(language: lang))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppleTheme.label)
                                    Text("Bir dev süreci RAM eşiğini aştığında macOS bildirimi gönderilir.".localized(language: lang))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppleTheme.secondaryLabel)
                                }
                            }
                            .toggleStyle(.checkbox)

                            if engine.notificationsEnabled {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("RAM Uyarı Eşiği".localized(language: lang))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppleTheme.label)
                                        Spacer()
                                        Text(engine.memoryAlertThresholdMB >= 1024 ? String(format: "%.1f GB", engine.memoryAlertThresholdMB / 1024.0) : "\(Int(engine.memoryAlertThresholdMB)) MB")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }

                                    Slider(value: $engine.memoryAlertThresholdMB, in: 500...4000, step: 100)
                                }
                            }
                        }
                    }

                    // Section 4: Özellik 8 — Politika Kuralları
                    SettingsSectionCard(title: "Politika Kuralları (Rule Engine)".localized(language: lang), icon: "slider.horizontal.3", iconColor: .indigo) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Otomatik Aksiyon Kuralları".localized(language: lang))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppleTheme.label)
                                    Text("Politika kuralları, belirli **eşik değerleri** aşan süreçlere karşı **otomatik aksiyon** almanı sağlar — sen uyumaktayken bile çalışır.".localized(language: lang))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppleTheme.secondaryLabel)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 20)
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(engine.policyRules.count)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.indigo)
                                    Text("kural".localized(language: lang))
                                        .font(.system(size: 10))
                                        .foregroundColor(AppleTheme.secondaryLabel)
                                }
                            }

                            if !engine.activeViolations.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12))
                                    Text("\(engine.activeViolations.count) " + "aktif kural ihlali tespit edildi".localized(language: lang))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // Section 5: Uygulama Bilgisi
                    SettingsSectionCard(title: "Uygulama Bilgisi".localized(language: lang), icon: "info.circle.fill", iconColor: .gray) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Uygulama Adı:".localized(language: lang))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppleTheme.secondaryLabel)
                                Spacer()
                                Text("PortGuard for macOS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppleTheme.label)
                            }

                            HStack {
                                Text("Sürüm:".localized(language: lang))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppleTheme.secondaryLabel)
                                Spacer()
                                Text("\(updater.currentVersion) (Build 2)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(AppleTheme.label)
                            }

                            HStack {
                                Text("Geliştirici:".localized(language: lang))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppleTheme.secondaryLabel)
                                Spacer()
                                Link("Orhan Kutay Bozkurt", destination: URL(string: "https://orhankutaybozkurt.com")!)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            }

                            Divider()
                                .background(AppleTheme.separator)
                                .padding(.vertical, 4)

                            HStack {
                                Button(action: {
                                    updater.checkForUpdates(lang: lang)
                                }) {
                                    Label("Güncellemeleri Denetle".localized(language: lang), systemImage: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(updater.isChecking)

                                Spacer()

                                if updater.isChecking {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text(lang == "tr" ? "Kontrol ediliyor..." : "Checking...")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppleTheme.secondaryLabel)
                                    }
                                } else if !updater.updateMessage.isEmpty {
                                    if updater.updateAvailable {
                                        Link(destination: URL(string: "https://github.com/okutaybozkurt/PortGuard/releases/latest")!) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.down.circle.fill")
                                                    .foregroundColor(.green)
                                                Text(updater.updateMessage)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.system(size: 11))
                                            Text(updater.updateMessage)
                                                .font(.system(size: 11))
                                                .foregroundColor(AppleTheme.secondaryLabel)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 620, idealWidth: 660, maxWidth: 800, minHeight: 520, idealHeight: 600, maxHeight: 800)
        .background(.regularMaterial)
        .preferredColorScheme(engine.selectedTheme.colorScheme)
        .onAppear {
            updater.checkForUpdates(lang: lang)
        }
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppleTheme.label)
            }

            Divider()
                .background(AppleTheme.separator)

            content
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppleTheme.separator, lineWidth: 0.8)
        )
    }
}
