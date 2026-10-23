# Changelog

🇬🇧 [English](CHANGELOG.md) · 🇹🇷 **Türkçe**

Bu projedeki tüm önemli değişiklikler bu dosyada belgelenir.

## [1.0.4] - 2026-10-23

### Added
- **Port çakışma çözücü:** Meşgul portta "Durdur ve Yeniden Başlat". Komut ve çalışma dizini onay penceresinde gösterilir; argümanlar shell'de yeniden yorumlanmadan başlatılır, kill öncesi süreç yeniden doğrulanır (PID yeniden kullanımına karşı).
- **Süreç detay paneli:** Çalışma dizini, tam komut satırı, PID/PPID ve başlangıç zamanı; Finder'da göster ve kopyala.
- **Hızlı arama paleti (⌥⌘P):** Port veya süreç adıyla ara, ↩ ile (ikinci onayla) durdur, ⌘↩ ile yeniden başlat. Ayarlar'dan kapatılabilir.

### Changed
- Popover yenilendi: Port / RAM / CPU kartları ve RAM çubuklu satırlar.
- Menü çubuğu ikonu kalkan olarak kaldı; kural ihlalinde köşesinde alarm noktası belirir.
- macOS'a uygun komutlar: ⌘R yenile, ⌘F ara, ⌘D dashboard, ⌘, ayarlar; sabit genişlikli rakamlar, sistem seçim rengi, erişilebilirlik etiketleri ve popover'da tutarlı yarı saydam arka plan.

### Fixed
- Dashboard'daki çarpı (durdur) ikonu onay penceresi göstermiyordu (aynı view'daki iki SwiftUI `.alert` çakışıyordu); onay artık NSAlert ile gösterilir. Menü çubuğu popover'ındaki çarpı da artık onay ister.

### Performance
- Pencere/popover görünür değilken yenileme 20 sn'de bire iner, `nettop` ve bağlantı taraması atlanır; geçmiş kaydı dakikada en fazla bir kez yazılır; zamanlayıcı toleransı sistemin uyanmaları birleştirmesine izin verir.

### Known limitations
- Yeniden başlatma yalnızca aynı kullanıcının süreçlerinde çalışır ve ortam değişkenlerini/özgün kabuk ortamını yeniden üretmez (ör. `npm run dev` yerine `node ...` çalışır).

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
