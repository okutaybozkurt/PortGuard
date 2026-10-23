import Foundation

/// Hızlı arama paletinin saf filtre mantığı (View'dan bağımsız, test edilebilir).
public enum QuickSearchLogic {
    public static func filter(_ processes: [PortProcess], query: String) -> [PortProcess] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return processes.sorted { $0.port < $1.port } }

        let matches = processes.filter {
            $0.processName.lowercased().contains(q) || "\($0.port)".contains(q) || "\($0.pid)".contains(q)
        }
        // Tam port eşleşmesi önce, sonra port sırası.
        return matches.sorted { a, b in
            let aExact = "\(a.port)" == q, bExact = "\(b.port)" == q
            if aExact != bExact { return aExact }
            return a.port < b.port
        }
    }

    /// Sorgu geçerli bir port numarasıysa ve hiçbir süreç onu dinlemiyorsa o portu döner.
    public static func freePort(for query: String, in processes: [PortProcess]) -> Int? {
        guard let port = Int(query.trimmingCharacters(in: .whitespaces)),
              port > 0, port < 65536 else { return nil }
        return processes.contains(where: { $0.port == port }) ? nil : port
    }

    /// Seçili id sonuçlarda varsa onun indeksi, yoksa ilk satır (0).
    public static func selectionIndex(id: String?, in results: [PortProcess]) -> Int {
        guard let id = id, let i = results.firstIndex(where: { $0.id == id }) else { return 0 }
        return i
    }

    /// Kill öncesi doğrulama: hedef aynı pid+port ile hâlâ aktif mi?
    public static func isStillActive(_ target: PortProcess, in active: [PortProcess]) -> Bool {
        active.contains { $0.pid == target.pid && $0.port == target.port }
    }

    public static func clampedSelection(_ index: Int, count: Int) -> Int {
        count <= 0 ? 0 : min(max(index, 0), count - 1)
    }
}
