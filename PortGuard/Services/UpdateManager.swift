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
                    
                    if latestVersion.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                        self.updateMessage = "Yeni Sürüm (v\(latestVersion)) Mevcut! İndirmek için tıklayın."
                        self.updateAvailable = true
                    } else {
                        self.updateMessage = "En güncel sürümü kullanıyorsunuz."
                        self.updateAvailable = false
                    }
                } catch {
                    self.updateMessage = "Güncelleme bilgisi okunamadı."
                }
            }
        }
        task.resume()
    }
}
