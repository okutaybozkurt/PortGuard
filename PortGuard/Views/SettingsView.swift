import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.dismiss) private var dismiss

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("PortGuard Ayarları")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppleTheme.label)
                Spacer()
                Button("Tamam") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()

            Divider()
                .background(AppleTheme.separator)

            Form {
                Section(header: Text("Görünüm ve İzleme").bold()) {
                    Toggle(isOn: $engine.showInDock) {
                        Text("Dock üzerinde göster (Dock Icon)")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)

                    Toggle(isOn: $engine.filterDevOnly) {
                        Text("Varsayılan olarak sadece geliştirici servislerini filtrele")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Otomatik Yenileme Sıklığı:")
                            Spacer()
                            Text(verbatim: "\(Int(engine.refreshInterval)) saniye")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $engine.refreshInterval, in: 2...30, step: 1)
                        Text("PortGuard'ın arka planda portları ve kaynakları ne sıklıkla izleyeceğini belirler.")
                            .font(.caption)
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                Section(header: Text("Özel Dev Servisi Filtreleri").bold()) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ek Özel Süreç İsimleri (virgülle ayırın):")
                            .font(.caption)
                        TextField("Örn: my-app-service, elixir, beam.smp, custom-tool", text: $engine.customDevKeywordsInput)
                            .textFieldStyle(.roundedBorder)
                        Text("PortGuard varsayılan olarak node, python, docker, dart, java, go, ruby vb. tanır.")
                            .font(.caption2)
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                Section(header: Text("RAM ve Bildirim Uyarıları").bold()) {
                    Toggle(isOn: $engine.notificationsEnabled) {
                        Text("Yüksek RAM tüketim bildirimlerini aktifleştir")
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if engine.notificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("RAM Uyarı Eşiği:")
                                Spacer()
                                Text(verbatim: engine.memoryAlertThresholdMB >= 1024 ? String(format: "%.1f GB", engine.memoryAlertThresholdMB / 1024.0) : "\(Int(engine.memoryAlertThresholdMB)) MB")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            Slider(value: $engine.memoryAlertThresholdMB, in: 500...4000, step: 100)
                            Text("Bu eşiği aşan bir dev süreci algılandığında macOS bildirimi gönderilir.")
                                .font(.caption)
                                .foregroundColor(AppleTheme.secondaryLabel)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Divider()

                Section(header: Text("Uygulama Bilgisi").bold()) {
                    HStack {
                        Text("Sürüm:")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    HStack {
                        Text("Geliştirici:")
                        Spacer()
                        Text("Orhan Kutay Bozkurt")
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 520, idealWidth: 600, maxWidth: 760, minHeight: 480, idealHeight: 620, maxHeight: 900)
        .background(.regularMaterial)
    }
}
