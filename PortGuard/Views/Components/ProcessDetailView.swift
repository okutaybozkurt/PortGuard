import SwiftUI
import AppKit

/// Süreç detay popover'ı. Komut satırı sır içerebilir: yalnızca ekranda gösterilir, loglanmaz.
public struct ProcessDetailView: View {
    public let process: PortProcess
    public let language: String
    public let load: (@escaping (ProcessDetail?) -> Void) -> Void

    @State private var detail: ProcessDetail?
    @State private var isLoading = true
    @State private var copied = false

    public init(process: PortProcess, language: String, load: @escaping (@escaping (ProcessDetail?) -> Void) -> Void) {
        self.process = process
        self.language = language
        self.load = load
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Süreç Detayı".localized(language: language))
                .font(.system(size: 13, weight: .bold))

            if isLoading {
                ProgressView().controlSize(.small)
            } else if let d = detail {
                field("Çalışma Dizini".localized(language: language), value: d.cwd ?? "—") {
                    if let cwd = d.cwd {
                        Button {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cwd)
                        } label: { Label("Finder'da Göster".localized(language: language), systemImage: "folder") }
                        .controlSize(.small)
                    }
                }
                field("Komut".localized(language: language), value: d.command) {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(d.command, forType: .string)
                        copied = true
                    } label: {
                        Label((copied ? "Kopyalandı" : "Kopyala").localized(language: language), systemImage: "doc.on.doc")
                    }
                    .controlSize(.small)
                }
                HStack(spacing: 16) {
                    Text(verbatim: "PID \(d.pid)")
                    Text(verbatim: "PPID \(d.ppid)" + (d.parentName.map { " (\($0))" } ?? ""))
                    Text("\("Çalışma süresi".localized(language: language)): \(process.formattedUptime)")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppleTheme.secondaryLabel)
                if let started = d.startedAt {
                    Text("\("Başlangıç".localized(language: language)): \(started.formatted(date: .abbreviated, time: .standard))")
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
            } else {
                Text("Detay alınamadı.".localized(language: language))
                    .font(.system(size: 12))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }
        }
        .padding(14)
        .frame(width: 380, alignment: .leading)
        .onAppear {
            load { result in
                detail = result
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private func field<Actions: View>(_ title: String, value: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundColor(AppleTheme.secondaryLabel)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
            actions()
        }
    }
}
