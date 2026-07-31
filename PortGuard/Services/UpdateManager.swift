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
    public let currentVersion = "1.0.1" // Hardcoded for this build

    public init() {}
    
    public func checkForUpdates() {
        DispatchQueue.main.async {
            self.isChecking = true
            self.updateMessage = "Güncellemeler kontrol ediliyor..."
            self.updateAvailable = false
        }
        
        guard let url = URL(string: repoURL) else { return }
        
        var request = URLRequest(url: url)
        // Add a User-Agent or GitHub API might reject the request
        request.setValue("PortGuard-MacApp", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isChecking = false
                
                if let error = error {
                    self.updateMessage = "Hata: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.updateMessage = "Veri alınamadı."
                    return
                }
                
                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    let latestVersion = release.tag_name.replacingOccurrences(of: "v", with: "")
                    
                    if latestVersion != self.currentVersion {
                        self.updateMessage = "Yeni sürüm bulundu! (\(latestVersion))"
                        self.updateAvailable = true
                        
                        // Offer to open the URL
                        self.promptUpdate(url: release.html_url, version: latestVersion)
                    } else {
                        self.updateMessage = "Sürümünüz güncel."
                        self.updateAvailable = false
                    }
                } catch {
                    self.updateMessage = "Güncelleme bilgisi okunamadı."
                }
            }
        }
        task.resume()
    }
    
    private func promptUpdate(url: String, version: String) {
        let alert = NSAlert()
        alert.messageText = "Yeni Sürüm Mevcut"
        alert.informativeText = "PortGuard'ın yeni bir sürümü (v\(version)) yayınlandı. İndirmek ister misiniz?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Şimdi İndir")
        alert.addButton(withTitle: "Daha Sonra")
        
        // Ensure alert pops up in front
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let downloadUrl = URL(string: url) {
                NSWorkspace.shared.open(downloadUrl)
            }
        }
    }
}
