import SwiftUI

public struct SettingsView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.dismiss) private var dismiss

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PortGuard Ayarları")
                    .font(.headline)
                    .bold()
                Spacer()
                Button("Kapat") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            Form {
                Section(header: Text("Görünüm ve İzleme").bold()) {
                    Toggle("Dock üzerinde göster (Dock Icon)", isOn: $engine.showInDock)
                        .padding(.vertical, 2)

                    Toggle("Varsayılan olarak sadece geliştirici servislerini filtrele", isOn: $engine.filterDevOnly)
                        .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Otomatik Yenileme Sıklığı:")
                            Spacer()
                            Text("\(Int(engine.refreshInterval)) saniye")
                                .bold()
                        }
                        Slider(value: $engine.refreshInterval, in: 2...30, step: 1)
                        Text("PortGuard'ın arka planda portları ve kaynakları ne sıklıkla izleyeceğini belirler.")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                Section(header: Text("RAM ve Bildirim Uyarıları").bold()) {
                    Toggle("Yüksek RAM tüketim bildirimlerini aktifleştir", isOn: $engine.notificationsEnabled)

                    if engine.notificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("RAM Uyarı Eşiği:")
                                Spacer()
                                Text(engine.memoryAlertThresholdMB >= 1024 ? String(format: "%.1f GB", engine.memoryAlertThresholdMB / 1024.0) : "\(Int(engine.memoryAlertThresholdMB)) MB")
                                    .bold()
                            }
                            Slider(value: $engine.memoryAlertThresholdMB, in: 500...4000, step: 100)
                            Text("Bu eşiği aşan bir dev süreci algılandığında macOS bildirimi gönderilir.")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Geliştirici:")
                        Spacer()
                        Text("Orhan Kutay Bozkurt")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 480)
    }
}
