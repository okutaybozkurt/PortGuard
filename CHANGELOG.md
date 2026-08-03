# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-08-04

### Added
- **Çoklu Seçim ve Toplu İşlem (Batch Kill):** Kullanıcılar artık dashboard üzerinden yanlarındaki kutucukları işaretleyerek birden fazla süreci tek seferde "Seçilenleri Durdur" butonuyla kapatabiliyor.
- **Süreç Bilgi Asistanı (Process Info Popover):** Süreç listesindeki servislerin (node, electron, python, docker, dart vb.) yanına eklenen (i) ikonuna tıklayarak söz konusu servisin ne işe yaradığı hakkında anında bilgi alabilirsiniz.
- **Anlık Dil Desteği (Türkçe/İngilizce):** Ayarlar bölümüne uygulamanın dilini *çalışma anında*, uygulamayı yeniden başlatmaya gerek duymadan değiştirebilen dil seçici eklendi.
- **Otomatik Güncelleme Denetleyici:** Uygulama içerisine GitHub API üzerinden en son sürümleri denetleyen ve tek tıkla kurulum (.dmg) sayfasına yönlendiren akıllı `UpdateManager` modülü eklendi.
- **Geliştirici Portfolyosu:** Ayarlar sekmesindeki geliştirici ismi doğrudan kişisel web sitesine (orhankutaybozkurt.com) yönlendirildi.
- **Yayın Otomasyonu:** Geliştiriciler için sürüm ve derleme numaralarını otomatik güncelleyen `bump_version.sh` betiği eklendi.

### Changed
- Sürüm numarası dinamik hale getirildi; kod yerine `Info.plist` üzerinden okunacak şekilde mimari güncellendi.
- README.md yeni özellikler ve güvenlik politikaları ile güncellendi.
- Süreç sonlandırma mantığı sert `kill -9` (SIGKILL) yerine daha güvenli ve kararlı olan `kill -15` (SIGTERM) ile değiştirildi.
