import Foundation
import AppKit

public struct GitHubRelease: Codable {
    public let tag_name: String
    public let html_url: String
    public let name: String
    public let body: String
}

public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    @Published public var isChecking: Bool = false
    @Published public var updateMessage: String = ""
    @Published public var updateAvailable: Bool = false
    
    private let repoURL = "https://api.github.com/repos/okutaybozkurt/PortGuard/releases/latest"
    public var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public init() {}
    
    /// Check for updates with localized messages.
    public func checkForUpdates(lang: String = "tr") {
        let checking  = lang == "tr" ? "Güncellemeler kontrol ediliyor..." : "Checking for updates..."
        let errorMsg  = lang == "tr" ? "Bağlantı hatası." : "Connection error."
        let noData    = lang == "tr" ? "Veri alınamadı." : "No data received."
        let upToDate  = lang == "tr" ? "En güncel sürümü kullanıyorsunuz." : "You're up to date."
        let parseFail = lang == "tr" ? "Güncelleme bilgisi okunamadı." : "Could not parse update info."

        DispatchQueue.main.async {
            self.isChecking = true
            self.updateMessage = checking
            self.updateAvailable = false
        }

        guard let url = URL(string: repoURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("PortGuard-MacApp", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isChecking = false

                if error != nil {
                    self.updateMessage = errorMsg
                    return
                }

                guard let data = data else {
                    self.updateMessage = noData
                    return
                }

                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    let latestVersion = release.tag_name.replacingOccurrences(of: "v", with: "")

                    if latestVersion.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                        self.updateMessage = lang == "tr"
                            ? "Yeni sürüm v\(latestVersion) mevcut — indirmek için tıklayın."
                            : "v\(latestVersion) available — click to download."
                        self.updateAvailable = true
                    } else {
                        self.updateMessage = upToDate
                        self.updateAvailable = false
                    }
                } catch {
                    self.updateMessage = parseFail
                }
            }
        }
        task.resume()
    }
}
