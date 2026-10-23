import SwiftUI
import Combine

/// Palet durumu: sorgu, sonuçlar, seçim. Klavye olaylarını panel controller'ı yönlendirir.
public final class QuickSearchModel: ObservableObject {
    @Published public var query: String = "" { didSet { selectedID = nil; pendingKillID = nil } }
    @Published public var processes: [PortProcess] = [] {
        didSet {
            if let p = pendingKillID, !processes.contains(where: { $0.id == p }) { pendingKillID = nil }
        }
    }
    /// Seçim index yerine süreç kimliğiyle tutulur; yenilemede kaybolursa ilk satıra düşer.
    @Published public var selectedID: String?
    /// Enter ile durdurma için ikinci onay bekleyen süreç.
    @Published public var pendingKillID: String?

    public init() {}

    public var results: [PortProcess] { QuickSearchLogic.filter(processes, query: query) }
    public var freePort: Int? { QuickSearchLogic.freePort(for: query, in: processes) }
    public var selectionIndex: Int { QuickSearchLogic.selectionIndex(id: selectedID, in: results) }
    public var selected: PortProcess? {
        let r = results
        return r.isEmpty ? nil : r[selectionIndex]
    }

    public func move(_ delta: Int) {
        let r = results
        guard !r.isEmpty else { return }
        selectedID = r[QuickSearchLogic.clampedSelection(selectionIndex + delta, count: r.count)].id
        pendingKillID = nil
    }
}

public struct QuickSearchView: View {
    @ObservedObject var model: QuickSearchModel
    let language: String
    @FocusState private var focused: Bool

    public init(model: QuickSearchModel, language: String) {
        self.model = model
        self.language = language
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(AppleTheme.secondaryLabel)
                TextField("Port, süreç adı veya PID ara…".localized(language: language), text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .focused($focused)
            }
            .padding(14)

            let results = model.results
            if let port = model.freePort {
                Divider()
                Text("Port \(port) " + "boş ✓".localized(language: language))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            if !results.isEmpty {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, proc in
                                row(proc, selected: index == model.selectionIndex, confirming: proc.id == model.pendingKillID).id(index)
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 300)
                    .onChange(of: model.selectionIndex) { proxy.scrollTo($0) }
                }
                Divider()
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .padding(8)
            }
        }
        .frame(width: 560)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { focused = true }
    }

    private var hint: String {
        let stop = "Durdur".localized(language: language)
        let restart = "Durdur ve Yeniden Başlat".localized(language: language)
        let close = "Kapat".localized(language: language)
        return "↩ \(stop)   ⌘↩ \(restart)   esc \(close)"
    }

    private func row(_ p: PortProcess, selected: Bool, confirming: Bool) -> some View {
        HStack(spacing: 12) {
            Text(verbatim: "\(p.port)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .frame(width: 56, alignment: .leading)
            Text(p.processName).font(.system(size: 13, weight: .semibold))
            Text(verbatim: "PID \(p.pid)").font(.system(size: 11)).foregroundColor(AppleTheme.secondaryLabel)
            Spacer()
            if confirming {
                Text("tekrar ↩ ile onayla".localized(language: language))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.red)
            }
            if !p.isKillable { Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(AppleTheme.secondaryLabel) }
            Text(p.formattedMemory).font(.system(size: 12, design: .rounded)).foregroundColor(AppleTheme.secondaryLabel)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        .cornerRadius(8)
    }
}
