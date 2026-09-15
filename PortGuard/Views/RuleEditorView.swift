import SwiftUI

/// Özellik 8 — Rule editor sheet for creating, editing, and managing PolicyRules.
public struct RuleEditorView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.dismiss) private var dismiss

    @State private var showAddRule = false
    @State private var editingRule: PolicyRule? = nil
    @State private var showRuleInfo = false

    public init(engine: PortMonitorEngine) {
        self.engine = engine
    }

    private var lang: String { engine.appLanguage }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.indigo)
                    Text("Otomatik Politika Kuralları".localized(language: lang))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppleTheme.label)
                }
                Spacer()
                Button(action: { showAddRule = true }) {
                    Label("Kural Ekle".localized(language: lang), systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button("Kapat".localized(language: lang)) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider().background(AppleTheme.separator)

            // ── Bilgi Kutusu ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                Button(action: { withAnimation(.spring(response: 0.3)) { showRuleInfo.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.indigo)
                        Text("Politika Kuralları Nedir?".localized(language: lang))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppleTheme.label)
                        Spacer()
                        Image(systemName: showRuleInfo ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.indigo.opacity(0.05))
                }
                .buttonStyle(.plain)

                if showRuleInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Politika kuralları, belirli **eşik değerleri** aşan süreçlere karşı **otomatik aksiyon** almanı sağlar — sen uyumaktayken bile çalışır.".localized(language: lang))
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.label)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(alignment: .top, spacing: 16) {
                            RuleInfoCard(
                                icon: "memorychip",
                                color: .orange,
                                title: "RAM Eşiği".localized(language: lang),
                                desc: "Örn: node 2 GB'yi aşarsa bildirim al. Bellek sızıntısını erken yakala.".localized(language: lang)
                            )
                            RuleInfoCard(
                                icon: "cpu",
                                color: .red,
                                title: "CPU Eşiği".localized(language: lang),
                                desc: "Örn: python %80 CPU kullanırsa otomatik sonlandır.".localized(language: lang)
                            )
                            RuleInfoCard(
                                icon: "clock",
                                color: .blue,
                                title: "Çalışma Süresi".localized(language: lang),
                                desc: "Örn: dev server 24 saati aşarsa 'Unutulan Süreç?' bildirimi al.".localized(language: lang)
                            )
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 11))
                            Text("Kural ihlali algılandığında bildirim gönderilir ve/veya süreç SIGTERM ile nazikçe sonlandırılır.".localized(language: lang))
                                .font(.system(size: 11))
                                .foregroundColor(AppleTheme.secondaryLabel)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.indigo.opacity(0.03))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider().background(AppleTheme.separator)
            }

            // Active violations banner
            if !engine.activeViolations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(engine.activeViolations.count) " + "aktif kural ihlali tespit edildi".localized(language: lang), systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                    ForEach(engine.activeViolations) { violation in
                        Text("• \(violation.description)")
                            .font(.system(size: 11))
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.07))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.red.opacity(0.2)), alignment: .bottom)
            }

            if engine.policyRules.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(engine.policyRules) { rule in
                        RuleRow(rule: rule, language: lang) {
                            editingRule = rule
                        } onToggle: {
                            var updated = rule
                            updated = PolicyRule(
                                id: rule.id,
                                processPattern: rule.processPattern,
                                conditionType: rule.conditionType,
                                threshold: rule.threshold,
                                action: rule.action,
                                isEnabled: !rule.isEnabled
                            )
                            engine.updateRule(updated)
                        }
                    }
                    .onDelete { engine.removeRule(at: $0) }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 600, idealWidth: 640, maxWidth: 800, minHeight: 420, idealHeight: 560)
        .background(.regularMaterial)
        .sheet(isPresented: $showAddRule) {
            RuleFormView(engine: engine, rule: nil)
        }
        .sheet(item: $editingRule) { rule in
            RuleFormView(engine: engine, rule: rule)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundColor(AppleTheme.secondaryLabel.opacity(0.4))
            Text("Henüz Kural Tanımlı Değil".localized(language: lang))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppleTheme.label)
            Text("\"Kural Ekle\" butonuyla RAM, CPU veya çalışma süresi bazlı otomatik politikalar tanımlayabilirsiniz.".localized(language: lang))
                .font(.system(size: 12))
                .foregroundColor(AppleTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            Button(action: { showAddRule = true }) {
                Label("İlk Kuralı Ekle".localized(language: lang), systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Rule Info Card

private struct RuleInfoCard: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppleTheme.label)
            }
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(AppleTheme.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: PolicyRule
    let language: String
    let onEdit: () -> Void
    let onToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Enabled toggle
            Button(action: onToggle) {
                Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(rule.isEnabled ? .indigo : AppleTheme.secondaryLabel.opacity(0.4))
            }
            .buttonStyle(.plain)

            // Condition icon
            Image(systemName: rule.conditionType.iconName)
                .font(.system(size: 14))
                .foregroundColor(rule.isEnabled ? .indigo : .gray)
                .frame(width: 20)

            // Rule description
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.summary)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(rule.isEnabled ? AppleTheme.label : AppleTheme.secondaryLabel)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(rule.action.rawValue.localized(language: language))
                        .appleBadgeStyle(color: actionColor(rule.action))
                    if !rule.isEnabled {
                        Text("Devre Dışı".localized(language: language))
                            .appleBadgeStyle(color: .gray)
                    }
                }
            }

            Spacer()

            // Edit button
            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .onHover { isHovered = $0 }
    }

    private func actionColor(_ action: PolicyRule.RuleAction) -> Color {
        switch action {
        case .alert:     return .orange
        case .kill:      return .red
        case .alertKill: return .red
        }
    }
}

// MARK: - Rule Form

private struct RuleFormView: View {
    @ObservedObject var engine: PortMonitorEngine
    @Environment(\.dismiss) private var dismiss

    let originalRule: PolicyRule?

    @State private var processPattern: String
    @State private var conditionType: PolicyRule.ConditionType
    @State private var threshold: Double
    @State private var action: PolicyRule.RuleAction
    @State private var isEnabled: Bool

    init(engine: PortMonitorEngine, rule: PolicyRule?) {
        self.engine       = engine
        self.originalRule = rule

        _processPattern = State(initialValue: rule?.processPattern ?? "")
        _conditionType  = State(initialValue: rule?.conditionType ?? .ramMB)
        _threshold      = State(initialValue: rule?.threshold ?? 1024)
        _action         = State(initialValue: rule?.action ?? .alert)
        _isEnabled      = State(initialValue: rule?.isEnabled ?? true)
    }

    private var lang: String { engine.appLanguage }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text((originalRule == nil ? "Yeni Kural" : "Kuralı Düzenle").localized(language: lang))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppleTheme.label)
                Spacer()
                Button("İptal".localized(language: lang)) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.bordered)
                Button((originalRule == nil ? "Ekle" : "Kaydet").localized(language: lang)) { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(threshold <= 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider()

            Form {
                Section("Süreç Filtresi".localized(language: lang)) {
                    TextField("Boş bırakırsanız tüm süreçlere uygulanır (örn: node, python)".localized(language: lang), text: $processPattern)
                }

                Section("Koşul".localized(language: lang)) {
                    Picker("Metrik:".localized(language: lang), selection: $conditionType) {
                        ForEach(PolicyRule.ConditionType.allCases) { t in
                            Label(t.rawValue.localized(language: lang), systemImage: t.iconName).tag(t)
                        }
                    }
                    HStack {
                        Text("Eşik Değer".localized(language: lang))
                        Spacer()
                        TextField("", value: $threshold, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        Text(conditionType.unit)
                            .foregroundColor(AppleTheme.secondaryLabel)
                            .frame(width: 30)
                    }
                    Slider(value: $threshold, in: thresholdRange, step: thresholdStep)
                }

                Section("Aksiyon".localized(language: lang)) {
                    Picker("Aksiyon:".localized(language: lang), selection: $action) {
                        ForEach(PolicyRule.RuleAction.allCases) { a in
                            Label(a.rawValue.localized(language: lang), systemImage: a.iconName).tag(a)
                        }
                    }
                    Toggle("Kuralı Aktifleştir".localized(language: lang), isOn: $isEnabled)
                }

                Section("Özet".localized(language: lang)) {
                    let preview = PolicyRule(
                        processPattern: processPattern,
                        conditionType: conditionType,
                        threshold: threshold,
                        action: action,
                        isEnabled: isEnabled
                    )
                    Text(preview.summary)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, idealWidth: 540, minHeight: 480)
        .background(.regularMaterial)
    }

    private var thresholdRange: ClosedRange<Double> {
        switch conditionType {
        case .ramMB:  return 256...8192
        case .cpuPct: return 10...100
        case .uptime: return 5...10080
        }
    }

    private var thresholdStep: Double {
        switch conditionType {
        case .ramMB:  return 128
        case .cpuPct: return 5
        case .uptime: return 15
        }
    }

    private func save() {
        let rule = PolicyRule(
            id: originalRule?.id ?? UUID(),
            processPattern: processPattern,
            conditionType: conditionType,
            threshold: threshold,
            action: action,
            isEnabled: isEnabled
        )
        if originalRule != nil {
            engine.updateRule(rule)
        } else {
            engine.addRule(rule)
        }
        dismiss()
    }
}
