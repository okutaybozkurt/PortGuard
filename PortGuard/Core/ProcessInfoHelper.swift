import Foundation
import SwiftUI

public struct ProcessInfoHelper {
    
    // Process name to info mapping
    static let infoDictionary: [String: [String: String]] = [
        "node": [
            "tr": "JavaScript çalışma ortamı. Genellikle React, Vue, Next.js gibi projelerin geliştirme sunucuları tarafından kullanılır.",
            "en": "JavaScript runtime. Usually used by development servers for projects like React, Vue, Next.js."
        ],
        "python": [
            "tr": "Python çalışma ortamı. Django, Flask sunucuları veya veri bilimi araçları tarafından kullanılıyor olabilir.",
            "en": "Python runtime. Might be used by Django, Flask servers or data science tools."
        ],
        "python3": [
            "tr": "Python 3 çalışma ortamı. Django, Flask sunucuları veya veri bilimi araçları tarafından kullanılıyor olabilir.",
            "en": "Python 3 runtime. Might be used by Django, Flask servers or data science tools."
        ],
        "electron": [
            "tr": "VS Code, Discord, Slack gibi masaüstü uygulamalarının altyapısını oluşturan web tabanlı çerçevedir. Bu süreç genellikle IDE'nizin veya bir uygulamanın arka plan işlemidir.",
            "en": "Web-based framework that powers desktop apps like VS Code, Discord, Slack. This is usually a background process of your IDE or an app."
        ],
        "language_server_macos_arm": [
            "tr": "Kullandığınız kod editörüne (IDE) otomatik kod tamamlama, sözdizimi vurgulama ve hata denetimi gibi özellikler sağlayan Dil Sunucusudur (Language Server).",
            "en": "A Language Server that provides features like autocomplete, syntax highlighting, and error checking to your code editor (IDE)."
        ],
        "rust-analyzer": [
            "tr": "Rust dili için kod editörlerine destek sağlayan Dil Sunucusudur (Language Server).",
            "en": "A Language Server providing support for the Rust language in code editors."
        ],
        "gopls": [
            "tr": "Go dili için kod editörlerine destek sağlayan Dil Sunucusudur (Language Server).",
            "en": "A Language Server providing support for the Go language in code editors."
        ],
        "docker": [
            "tr": "Docker konteyner altyapısıdır. Kapatırsanız çalışan konteynerleriniz bağlantı kopukluğu yaşayacaktır.",
            "en": "Docker container infrastructure. If killed, your running containers may disconnect."
        ],
        "com.docker.backend": [
            "tr": "Docker arka plan servisidir. Kapatırsanız Docker masaüstü düzgün çalışmayabilir.",
            "en": "Docker background service. If killed, Docker Desktop may stop working properly."
        ],
        "java": [
            "tr": "Java çalışma zamanı (JRE/JDK). Spring Boot uygulamaları, Minecraft veya Android Studio gibi araçlar tarafından kullanılıyor olabilir.",
            "en": "Java runtime environment. Might be used by Spring Boot apps, Minecraft, or Android Studio."
        ],
        "ruby": [
            "tr": "Ruby çalışma ortamı. Genellikle Ruby on Rails projeleri veya iOS geliştirmede CocoaPods tarafından kullanılır.",
            "en": "Ruby runtime environment. Usually used by Ruby on Rails projects or CocoaPods in iOS development."
        ],
        "php": [
            "tr": "PHP çalışma ortamı. Laravel veya yerel web sunucuları tarafından kullanılıyor olabilir.",
            "en": "PHP runtime environment. Might be used by Laravel or local web servers."
        ],
        "flutter": [
            "tr": "Flutter geliştirme aracı. Arka planda sıcak yeniden yükleme (hot reload) veya cihaz bağlantısı için port dinliyor olabilir.",
            "en": "Flutter development tool. Might be listening on a port for hot reload or device connections."
        ],
        "dart": [
            "tr": "Dart dili çalışma ortamı. Flutter projeleri veya Dart sunucuları tarafından kullanılır.",
            "en": "Dart runtime environment. Used by Flutter projects or Dart servers."
        ]
    ]

    public static func getInfo(for processName: String, languageCode: String) -> String? {
        let key = processName.lowercased()
        guard let entry = infoDictionary[key] else { return nil }
        return entry[languageCode] ?? entry["en"]
    }
}
