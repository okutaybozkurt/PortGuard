import SwiftUI

/// Özellik 6 — Geçmiş & Kayıtlar (History & Snapshots)
/// Clean tabular and card-based historical overview without cluttered charts.
public struct HistoryView: View {
    @ObservedObject var engine: PortMonitorEngine

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().background(AppleTheme.separator)

            if engine.recentHistory.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        summaryMetricsSection
                        topConsumersSection
                        dailyBreakdownSection
                    }
                    .padding(20)
                }
            }
        }
        .onAppear { engine.loadHistory() }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                Text("Geçmiş & Kayıtlar".localized(language: lang))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppleTheme.label)
            }

            Spacer()

            // Period selector (3 / 7 / 14 days)
            HStack(spacing: 0) {
                ForEach([3, 7, 14], id: \.self) { days in
                    Button(action: {
                        engine.historyDaysToShow = days
                        engine.loadHistory()
                    }) {
                        Text("\(days) " + "Gün".localized(language: lang))
                            .font(.system(size: 11, weight: engine.historyDaysToShow == days ? .bold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(engine.historyDaysToShow == days ? Color.accentColor.opacity(0.15) : Color.clear)
                            .foregroundColor(engine.historyDaysToShow == days ? .accentColor : AppleTheme.secondaryLabel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppleTheme.separator, lineWidth: 0.8))

            Button(action: { engine.loadHistory() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .help("Geçmişi Yenile".localized(language: lang))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Period Summary Metrics

    private var summaryMetricsSection: some View {
        let allSnaps = engine.recentHistory.values.flatMap { $0 }
        let totalSnaps = allSnaps.count
        let daysCount = engine.recentHistory.count
        let maxRAM = allSnaps.flatMap { $0.processes }.map(\.memoryMB).max() ?? 0
        let avgProcesses = totalSnaps > 0
            ? Double(allSnaps.map { $0.processes.count }.reduce(0, +)) / Double(totalSnaps)
            : 0.0

        return VStack(alignment: .leading, spacing: 10) {
            Text("Dönem Özeti".localized(language: lang))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppleTheme.label)

            HStack(spacing: 12) {
                HistoryMetricCard(
                    title: "Snapshot".localized(language: lang),
                    value: "\(totalSnaps)",
                    icon: "camera.fill",
                    color: .blue
                )
                HistoryMetricCard(
                    title: "İzleme Günü".localized(language: lang),
                    value: "\(daysCount)",
                    icon: "calendar",
                    color: .purple
                )
                HistoryMetricCard(
                    title: "Maks. RAM".localized(language: lang),
                    value: maxRAM >= 1024 ? String(format: "%.1f GB", maxRAM / 1024) : "\(Int(maxRAM)) MB",
                    icon: "memorychip.fill",
                    color: .red
                )
                HistoryMetricCard(
                    title: "Ort. Port".localized(language: lang),
                    value: String(format: "%.1f", avgProcesses),
                    icon: "network",
                    color: .teal
                )
            }
        }
    }

    // MARK: - Top RAM Consumers

    private var topConsumersSection: some View {
        let allSnaps = engine.recentHistory.values.flatMap { $0 }
        var procRAM: [String: [Double]] = [:]
        for snap in allSnaps {
            for p in snap.processes {
                procRAM[p.processName, default: []].append(p.memoryMB)
            }
        }
        let top5 = procRAM
            .map { (name: $0.key, avg: $0.value.reduce(0, +) / Double($0.value.count), peak: $0.value.max() ?? 0) }
            .sorted { $0.avg > $1.avg }
            .prefix(5)

        let maxAvg = top5.first?.avg ?? 1.0

        return VStack(alignment: .leading, spacing: 10) {
            Text("Dönemin En Çok RAM Tüketenleri".localized(language: lang))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppleTheme.label)

            if top5.isEmpty {
                Text("Aktif Süreç Yok".localized(language: lang))
                    .font(.system(size: 12))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(top5.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(idx == 0 ? .orange : AppleTheme.tertiaryLabel)
                                .frame(width: 20)

                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppleTheme.label)
                                .frame(minWidth: 100, alignment: .leading)

                            Spacer()

                            // Visual bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.orange.opacity(0.12))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.orange.opacity(0.75))
                                        .frame(width: max(4, geo.size.width * CGFloat(item.avg / max(maxAvg, 1.0))), height: 6)
                                }
                            }
                            .frame(width: 120, height: 6)

                            // Average RAM
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(item.avg >= 1024 ? String(format: "%.1f GB", item.avg / 1024) : "\(Int(item.avg)) MB")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                Text("Maks: " + (item.peak >= 1024 ? String(format: "%.1f GB", item.peak / 1024) : "\(Int(item.peak)) MB"))
                                    .font(.system(size: 9))
                                    .foregroundColor(AppleTheme.secondaryLabel)
                            }
                            .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppleTheme.separator, lineWidth: 0.6))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppleTheme.separator, lineWidth: 0.8))
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        let sortedDays = engine.recentHistory.sorted(by: { $0.key > $1.key })

        let cal = Calendar.current
        let isTR = (lang == "tr")

        return VStack(alignment: .leading, spacing: 10) {
            Text("Günlük Geçmiş & Snapshot Kayıtları".localized(language: lang))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppleTheme.label)

            VStack(spacing: 10) {
                ForEach(sortedDays, id: \.key) { date, snapshots in
                    let isToday = cal.isDateInToday(date)
                    let isYesterday = cal.isDateInYesterday(date)
                    let dateTitle: String = {
                        if isToday { return "Bugün".localized(language: lang) }
                        if isYesterday { return "Dün".localized(language: lang) }
                        let fmt = DateFormatter()
                        fmt.dateFormat = isTR ? "d MMMM yyyy" : "MMMM d, yyyy"
                        fmt.locale = Locale(identifier: isTR ? "tr_TR" : "en_US")
                        return fmt.string(from: date)
                    }()

                    let uniqueProcesses = Set(snapshots.flatMap { $0.processes.map(\.processName) })
                    let maxRAM = snapshots.flatMap { $0.processes }.map(\.memoryMB).max() ?? 0

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(isToday ? Color.green : Color.blue)
                                    .frame(width: 8, height: 8)
                                Text(dateTitle)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppleTheme.label)
                            }

                            Spacer()

                            HStack(spacing: 10) {
                                Text("\(snapshots.count) " + "kayıt".localized(language: lang))
                                    .font(.system(size: 11))
                                    .foregroundColor(AppleTheme.secondaryLabel)

                                Text("\(uniqueProcesses.count) " + "süreç".localized(language: lang))
                                    .appleBadgeStyle(color: .blue)

                                Text(maxRAM >= 1024 ? String(format: "%.1f GB", maxRAM / 1024) : "\(Int(maxRAM)) MB")
                                    .appleBadgeStyle(color: .orange)
                            }
                        }

                        // Process tags active on this day
                        if !uniqueProcesses.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(uniqueProcesses).sorted(), id: \.self) { name in
                                        Text(name)
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(NSColor.controlBackgroundColor))
                                            .cornerRadius(6)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppleTheme.separator, lineWidth: 0.6))
                                            .foregroundColor(AppleTheme.label)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppleTheme.separator, lineWidth: 0.8))
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(AppleTheme.secondaryLabel.opacity(0.4))
            Text("Henüz Geçmiş Verisi Yok".localized(language: lang))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppleTheme.label)
            Text("PortGuard açık kaldıkça her yenileme döngüsünde otomatik veri toplanır.\nÇalıştırılan süreçlerin kaynak kullanımı geçmişi burada listelenir.".localized(language: lang))
                .font(.system(size: 12))
                .foregroundColor(AppleTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Metric Card

private struct HistoryMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppleTheme.secondaryLabel)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppleTheme.label)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
    }
}
