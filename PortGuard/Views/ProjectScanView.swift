import SwiftUI

/// Özellik 5 — Sheet for scanning a project directory and showing port comparison.
public struct ProjectScanView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.dismiss) private var dismiss
    @State private var showScannerInfo = false

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.purple)
                    Text("Proje Port Tarayıcı".localized(language: lang))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                }
                Spacer()
                Button("Kapat".localized(language: lang)) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider().background(AppleTheme.separator)

            ScrollView {
                VStack(spacing: 16) {
                    // Scan section
                    scanSection

                    // Results
                    if let project = engine.scannedProject {
                        projectResultSection(project)
                        portComparisonSection(project)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 560, idealWidth: 600, maxWidth: 700, minHeight: 420, idealHeight: 520)
        .background(.regularMaterial)
    }

    // MARK: - Scan Section

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Açıklayıcı bilgi kutusu
            VStack(alignment: .leading, spacing: 0) {
                Button(action: { withAnimation(.spring(response: 0.3)) { showScannerInfo.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("Proje Port Tarayıcı Nedir?".localized(language: lang))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppleTheme.label)
                        Spacer()
                        Image(systemName: showScannerInfo ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.yellow.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                if showScannerInfo {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bu özellik, seçtiğin **proje klasörünü** otomatik tarayarak hangi portların kullanılmasını beklediğini tespit eder.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.label)

                        // Feature list
                        VStack(alignment: .leading, spacing: 6) {
                            FeatureRow(icon: "doc.fill", color: .green, text: "package.json → script içindeki PORT veya framework varsayılanını okur (Next.js: 3000, Vite: 5173…)".localized(language: lang))
                            FeatureRow(icon: "doc.plaintext", color: .blue, text: ".env / .env.local → PORT=XXXX satırını okur".localized(language: lang))
                            FeatureRow(icon: "shippingbox.fill", color: .cyan, text: "docker-compose.yml → ports: kısmındaki host portlarını listeler".localized(language: lang))
                            FeatureRow(icon: "iphone", color: .purple, text: "pubspec.yaml → Flutter web sunucusu (varsayılan 8080)".localized(language: lang))
                            FeatureRow(icon: "chevron.left.forwardslash.chevron.right", color: .yellow, text: "pyproject.toml / manage.py → Python/Django portunu bulur".localized(language: lang))
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)

                        Text("Tarama sonrasında, beklenen portların o an gerçekten **aktif olup olmadığını** yeşil ✓ / turuncu ⚠️ ile gösterir.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .padding(12)
                    .background(Color.yellow.opacity(0.04))
                    .cornerRadius(10)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            HStack(spacing: 12) {
                Button(action: openFolderPicker) {
                    Label("Proje Klasörü Seç".localized(language: lang), systemImage: "folder")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                if engine.scannedProject != nil {
                    Button(action: { engine.clearScannedProject() }) {
                        Label("Temizle".localized(language: lang), systemImage: "xmark.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // Feature row helper
    private struct FeatureRow: View {
        let icon: String
        let color: Color
        let text: String

        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 16)
                Text(text)
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Project Result

    private func projectResultSection(_ project: ProjectPortInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: project.projectType.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.purple)
                Text(project.projectName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppleTheme.label)
                Text(project.projectType.rawValue)
                    .appleBadgeStyle(color: .purple)
                Spacer()
                Text("\("Kaynak:".localized(language: lang)) \(project.sourceFile)")
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }

            Text(project.projectURL.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppleTheme.tertiaryLabel)
                .lineLimit(2)
                .truncationMode(.middle)

            HStack(spacing: 8) {
                Text("Beklenen Portlar:".localized(language: lang))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppleTheme.secondaryLabel)
                ForEach(project.expectedPorts, id: \.self) { port in
                    Text(verbatim: "\(port)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .appleBadgeStyle(color: .blue)
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppleTheme.separator, lineWidth: 0.8))
    }

    // MARK: - Port Comparison

    private func portComparisonSection(_ project: ProjectPortInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Port Karşılaştırması".localized(language: lang))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppleTheme.label)

            // Matching (active) ports
            if !engine.matchingProjectPorts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\("Aktif".localized(language: lang)) (\(engine.matchingProjectPorts.count))", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)

                    ForEach(engine.matchingProjectPorts) { proc in
                        HStack {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text(verbatim: ":\(proc.port)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                            Text(proc.processName)
                                .font(.system(size: 12))
                                .foregroundColor(AppleTheme.label)
                            Spacer()
                            Text(proc.formattedMemory)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            // Missing (not running) ports
            if !engine.missingProjectPorts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\("Çalışmıyor".localized(language: lang)) (\(engine.missingProjectPorts.count))", systemImage: "exclamationmark.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)

                    ForEach(engine.missingProjectPorts, id: \.self) { port in
                        HStack {
                            Circle().fill(Color.orange.opacity(0.5)).frame(width: 6, height: 6)
                            Text(verbatim: ":\(port)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue.opacity(0.5))
                            Text("Bu port şu an dinlenmiyor".localized(language: lang))
                                .font(.system(size: 12))
                                .foregroundColor(AppleTheme.secondaryLabel)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.04))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 2])))
                    }
                }
            }

            if engine.matchingProjectPorts.isEmpty && engine.missingProjectPorts.isEmpty {
                Text("Bu projeye ait beklenen port bulunamadı.".localized(language: lang))
                    .font(.system(size: 12))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppleTheme.separator, lineWidth: 0.8))
    }

    // MARK: - Folder Picker

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Proje Klasörü Seç".localized(language: lang)
        panel.prompt = "Tara".localized(language: lang)

        if panel.runModal() == .OK, let url = panel.url {
            engine.scanProject(at: url)
        }
    }
}
