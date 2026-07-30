# PortGuard (macOS MenuBar Port & Resource Monitor)
## Teknik Mimari, Altyapı ve Uygulama Planı Document V1

---

## 1. Proje Özeti ve Hedefler

### 1.1 Problem Tanımı
Yazılım geliştiriciler gün içerisinde `npm run dev`, `flutter run`, `vite`, `docker`, `python uvicorn` gibi birçok geliştirme sunucusunu ve servisini çalıştırır. Proje veya terminal sekmeleri kapatıldığında arka planda açık unutulan bu portlar ve süreçler (processes):
- Ciddi oranda **RAM (1 - 4 GB+)** ve **CPU (%15 - %30+)** tüketir.
- macOS cihazlarda **pil ömrünü hızlıca tüketir** ve cihazın ısınmasına neden olur.
- Yeni bir proje başlatıldığında `EADDRINUSE: address already in use` gibi port çakışması hatalarına yol açar.

### 1.2 Çözüm: PortGuard
PortGuard; macOS sistem çubuğunda (MenuBar) çalışan, arka planda geliştirme portlarını taranarak hangi servisin (Node, Dart, Python vb.) hangi portu kullandığını, ne kadar RAM tükettiğini gösteren ve tek tıkla ilgili süreci sonlandırmaya (kill) yarayan ultra hafif (lightweight) bir macOS uygulamasıdır.

---

## 2. Dağıtım ve Çalışma Stratejisi

- **Dağıtım Kanalı:** Web Üzerinden Doğrudan Dağıtım (.dmg / .zip).
  - *Gerekçe:* Mac App Store Sandbox kısıtlamaları (diğer süreçlerin PID ve RAM verilerini okuma engeli, `kill` yetkisi kısıtı) nedeniyle App Store yerine Apple Developer Notarization onaylı bağımsız dağıtım yöntemi seçilmiştir.
- **Dock & MenuBar Görünürlüğü:** 
  - Uygulama ilk etapta hem **MenuBar**'da aktif durumu gösterecek hem de **Dock** üzerinde görünür kalacaktır. (Daha sonra kullanıcı tercihine göre `Info.plist` ayarlarından gizleme seçeneği sunulacaktır).

---

## 3. Sistem Mimarisi ve Bileşenler

```
+-------------------------------------------------------------------+
|                        macOS UI Layer                             |
|    +------------------------+      +-------------------------+    |
|    |  MenuBarExtra (Icon)   |      |   Dock App & Window     |    |
|    +-----------+------------+      +------------+------------+    |
+----------------|--------------------------------|-----------------+
                 |                                |
                 +---------------+----------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|                       SwiftUI Core Layer                          |
|    +---------------------------------------------------------+    |
|    |                     PortMonitorEngine                   |    |
|    |  - Timer / Polling (Her 5-10 saniyede bir tetiklenir)   |    |
|    +---------------------------+-----------------------------+    |
+--------------------------------|----------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------+
|                   System Interop / Helper Layer                   |
|    +---------------------------------------------------------+    |
|    |                      ProcessManager                     |    |
|    |  1. Task: lsof -iTCP -sTCP:LISTEN -P -n                    |    |
|    |  2. Task: ps -o rss= -p <PID>                           |    |
|    |  3. Task: kill -9 <PID>                                 |    |
|    +---------------------------------------------------------+    |
+-------------------------------------------------------------------+
```

### 3.1 Veri Toplama Mantığı (Shell Commands)

1. **Aktif LISTEN Portlarını ve PID'leri Alma:**
   ```bash
   /usr/sbin/lsof -iTCP -sTCP:LISTEN -P -n
   ```
   *Örnek Çıktı Parsing:*
   ```text
   COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
   node    48291  orhan   23u  IPv4 ...      0t0  TCP *:3000 (LISTEN)
   dart    51029  orhan   12u  IPv4 ...      0t0  TCP *:8080 (LISTEN)
   ```

2. **PID Üzerinden Anlık RAM (RSS) Kullanımını Hesaplama:**
   ```bash
   ps -o rss= -p <PID>
   ```
   *(Elde edilen KB değeri `1024.0`'a bölünerek MB cinsine çevrilir).*

3. **Gerekli Filtreleme (White-list / Dev-process Filter):**
   Yalnızca geliştirici servisleri odak noktasına alınır:
   - `node`, `dart`, `python`, `python3`, `java`, `go`, `ruby`, `postgres`, `mysqld`, `docker` vb.
   - Sistem servisleri (`ControlCenter`, `httpd`, `rapportd`) listeden filtrelenerek gizlenir.

---

## 4. Xcode & SwiftUI Kod Yapısı

### 4.1 Veri Modeli (`PortProcess.swift`)
```swift
import Foundation

struct PortProcess: Identifiable, Hashable {
    let id = UUID()
    let pid: Int
    let processName: String
    let port: Int
    let memoryMB: Double
    
    var formattedMemory: String {
        if memoryMB >= 1024 {
            return String(format: "%.2f GB", memoryMB / 1024.0)
        } else {
            return String(format: "%.1f MB", memoryMB)
        }
    }
}
```

### 4.2 Uygulama Giriş Noktası (`PortGuardApp.swift`)
```swift
import SwiftUI

@main
struct PortGuardApp: App {
    @StateObject private var monitorEngine = PortMonitorEngine()

    var body: some Scene {
        // MenuBar Yapılandırması
        MenuBarExtra {
            PortPopOverView(engine: monitorEngine)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "network")
                if !monitorEngine.activeProcesses.isEmpty {
                    Text("\(monitorEngine.activeProcesses.count)")
                        .font(.caption2)
                        .bold()
                }
            }
        }
        .menuBarExtraStyle(.window)

        // Dock Görünümü / Ana Pencere Yapılandırması
        WindowGroup {
            MainDashboardView(engine: monitorEngine)
        }
    }
}
```

### 4.3 Sistem İşlem Yöneticisi (`ProcessManager.swift`)
```swift
import Foundation

class ProcessManager {
    static let shared = ProcessManager()

    func fetchActiveDevPorts() -> [PortProcess] {
        let lsofOutput = runCommand(executable: "/usr/sbin/lsof", arguments: ["-iTCP", "-sTCP:LISTEN", "-P", "-n"])
        return parseLsofOutput(lsofOutput)
    }

    func killProcess(pid: Int) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/kill")
        task.arguments = ["-9", "\(pid)"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Process terminate hatası: \(error)")
            return false
        }
    }

    private func getMemoryUsageMB(pid: Int) -> Double {
        let output = runCommand(executable: "/bin/ps", arguments: ["-o", "rss=", "-p", "\(pid)"])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if let kb = Double(trimmed) {
            return kb / 1024.0
        }
        return 0.0
    }

    private func runCommand(executable: String, arguments: [String]) -> String {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func parseLsofOutput(_ rawText: String) -> [PortProcess] {
        var results: [PortProcess] = []
        let lines = rawText.components(separatedBy: .newlines)
        
        // İlk satır header (COMMAND PID USER ...) olduğu için skip edilir
        for line in lines.dropFirst() {
            let parts = line.split(separator: " ").map { String($0) }
            guard parts.count >= 9 else { continue }
            
            let command = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let nameField = parts[8] // örn: *:3000 veya 127.0.0.1:8080
            
            if let portString = nameField.components(separatedBy: ":").last,
               let port = Int(portString) {
                
                let ram = getMemoryUsageMB(pid: pid)
                let item = PortProcess(pid: pid, processName: command, port: port, memoryMB: ram)
                results.append(item)
            }
        }
        return results
    }
}
```

---

## 5. Uygulama ve Geliştirme Yol Haritası (Roadmap)

| Aşama | Başlık | Detay / Çıktı |
| :--- | :--- | :--- |
| **Faz 1** | Xcode Projesi & Iskelet | macOS SwiftUI projesinin oluşturulması, MenuBarExtra entegrasyonu. |
| **Faz 2** | Core Engine & Command Parsing | `lsof` ve `ps` çıktılarının Swift modellerine dönüştürülmesi. |
| **Faz 3** | UI & Popover Geliştirmesi | Aktif port listesi, RAM sayaçları ve tek tıkla `Kill Process` aksiyonu. |
| **Faz 4** | Eşik Uyarısı (Notifications) | 1 GB RAM'i aşan servisler için arka planda macOS bildirim tetikleyicisi. |
| **Faz 5** | Build, Archive & DMG Output | Notarization hazırlığı, `.dmg` oluşturulması ve lokal testler. |

---
*Hazırlayan:* Orhan Kutay Bozkurt
*Tarih:* Temmuz 2026
