import Foundation

/// Özellik 6 — Persists periodic `PortSnapshot` objects to disk as daily JSON files.
/// Storage location: `~/.portguard/history/YYYY-MM-DD.json`
/// Each file contains an array of `PortSnapshot` objects recorded that day.
public final class HistoryStore {
    public static let shared = HistoryStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private lazy var historyDirectory: URL = {
        let base = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".portguard/history", isDirectory: true)
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    public init() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting     = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public API

    /// Append a new snapshot to today's history file.
    public func append(snapshot: PortSnapshot) {
        let url = fileURL(for: Date())
        var snapshots = load(from: url)
        snapshots.append(snapshot)

        // Cap to 2000 entries per day (~1 per 43 seconds with 5s interval) to avoid bloat
        if snapshots.count > 2000 {
            snapshots = Array(snapshots.suffix(2000))
        }

        save(snapshots, to: url)
    }

    /// Load all snapshots for a specific date.
    public func load(for date: Date) -> [PortSnapshot] {
        load(from: fileURL(for: date))
    }

    /// Load snapshots for the last N days (today inclusive).
    public func loadRecent(days: Int = 7) -> [Date: [PortSnapshot]] {
        var result: [Date: [PortSnapshot]] = [:]
        let calendar = Calendar.current

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            result[dayStart] = load(for: date)
        }
        return result
    }

    /// Delete history older than `days` days to reclaim disk space.
    public func purgeOlderThan(days: Int) {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) else { return }

        let files = (try? fileManager.contentsOfDirectory(
            at: historyDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []

        for file in files {
            if let created = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
               created < cutoff {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    /// Total number of daily history files on disk.
    public var historyFilesCount: Int {
        (try? fileManager.contentsOfDirectory(at: historyDirectory, includingPropertiesForKeys: nil))?.count ?? 0
    }

    // MARK: - Private helpers

    private func fileURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = formatter.string(from: date) + ".json"
        return historyDirectory.appendingPathComponent(filename)
    }

    private func load(from url: URL) -> [PortSnapshot] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([PortSnapshot].self, from: data)) ?? []
    }

    private func save(_ snapshots: [PortSnapshot], to url: URL) {
        guard let data = try? encoder.encode(snapshots) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
