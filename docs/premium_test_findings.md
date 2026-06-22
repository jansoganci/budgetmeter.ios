# Premium Test Bulguları

**Tarih:** 22 Haziran 2026  
**Test ortamı:** DEBUG build, Ayarlar → DEBUG → Premium Mode  
**Amaç:** Premium özelliklerini manuel test edip sorunlu alanları kayıt altına almak

---

## Premium Nasıl Test Edildi?

1. Xcode’dan **Debug** build ile simülatör/cihazda uygulama çalıştırıldı.
2. **Ayarlar → DEBUG → Premium Mode** açılarak tüm premium kapılar bypass edildi (StoreKit sandbox kullanılmadı).
3. Her özellik hem **Premium Mode KAPALI** (kilit/paywall) hem **AÇIK** (erişim) senaryolarında kontrol edildi.

> Not: Release build’de DEBUG toggle görünmez. Gerçek satın alma testi için StoreKit sandbox (`com.budgetmeter.premium.lifetime`) ayrıca doğrulanmalı.

---

## Özet Tablo

| Alan | Durum | Öncelik |
|------|-------|---------|
| Insights | ✅ Açılıyor | — |
| Gelir/Gider ekleme (tek seferlik + recurring) | ✅ Çözüldü | — |
| Özel kategori ekleme | ✅ Çözüldü | — |
| Birden fazla savings goal | ✅ Çözüldü | — |
| Recurring expenses (özel) | ✅ Çözüldü | — |
| Premium temalar | ✅ Çözüldü | — |
| Tema kapsamı (neyin değişeceği) | ✅ Karar verildi | — |
| Widget | ✅ Çözüldü | — |
| Veri dışa aktarma | ✅ Çalışıyor | — |
| PDF export tasarımı | ✅ Çözüldü | — |
| Face ID | ⚠️ Kurulum OK, kilitleme yok | Yüksek |
| Daily encourage notification | ✅ Çözüldü | — |
| İlk kurulumda bildirim izni | ✅ Karar verildi | — |
| Cloud backup kavramı | ❓ Kafa karışıklığı | Ürün / UX |
| Para birimi (row-level) | ✅ Kayıt bazlı `currencyCode` eklendi; dönüşüm yok | — |

---

## Para Birimi Notu (Haziran 2026)

- Hesap tercihi (`preferred_currency_code`) yalnızca **yeni kayıtlar** için varsayılan.
- Kayıtlı tutarların gerçek para birimi satır bazında `currencyCode` alanında saklanır.
- Tercih sonradan değişse bile eski kayıtların para birimi **değiştirilmez**.
- Kur dönüşümü veya geçmiş kur çıkarımı **yok**.

---

## Detaylı Bulgular

### 1. Insights — ✅ OK

Premium Mode açıkken Insights sekmesi açılıyor, paywall engeli yok.

---

### 2. Gelir / Gider Ekleme — ✅ Çözüldü

**Önceki gözlem:** Insights açılıyor ancak gelir veya gider eklemeye çalışınca hemen hata alınıyordu.

**Kapsam (doğrulandı):**
- Tek seferlik gelir
- Tek seferlik gider
- Recurring gelir
- Recurring gider

**Durum:** Akış düzeltildi ve manuel test geçti. Kategori seçimi → tutar girme → kayıt başarılı; sonuç doğru bölümde görünüyor.

**Çözüm Notu:** Unicode kategori adları destekleniyor. Weekly bölümü eklendi. Tek seferlik kalemlerde frequency sorusu kaldırıldı. Kategori oluşturma sonrası tutar girişine devam ediliyor. Duplicate validation aynı gelir/gider tipinde normalize edilmiş isimleri engelliyor. Build, `CategoryValidationServiceTests`, `IncomeExpenseFlowTests` ve manuel test geçti.

---

### 3. Özel Kategori Ekleme — ✅ Çözüldü

**Önceki gözlem:** Varsayılan kategoriler (maaş, kira vb.) çalışıyordu; kullanıcının eklediği yeni kategori kaydedilmiyor / görünmüyordu.

**Durum:** Özel kategori oluşturma düzeltildi ve manuel test geçti. Türkçe, Arapça, Çince ve diğer Unicode adlar destekleniyor. İkon seçimi çalışıyor; kategori adı metninde emoji reddediliyor. Varsayılan kategoriler etkilenmedi.

**Çözüm Notu:** Unicode kategori adları destekleniyor. Weekly bölümü eklendi. Tek seferlik kalemlerde frequency sorusu kaldırıldı. Duplicate validation aynı gelir/gider tipinde normalize edilmiş isimleri engelliyor. Kategori oluşturma sonrası tutar girişine devam ediliyor.

---

### 4. Birden Fazla Savings Goal — ✅ Çözüldü

**Durum (doğrulandı):**
- Core premium multiple-goal capability düzeltildi.
- Premium kullanıcılar artık birden fazla savings goal oluşturabiliyor.
- Free kullanıcılar tek goal limitiyle kalıyor.
- İkinci goal, birinci goal’u overwrite etmiyor.
- Build geçti, `BasicSavingsIntegrationTests` geçti.

**UI/UX durumu:** Savings Goals UI/UX polish tamamlandı.

**Çözüm Notu:**
- Home Goal quick action akışı güncellendi.
- Savings Goals ekranı ve Add Goal modal localization sorunları giderildi.
- Header hizası, amount input focus, keyboard Done ve picker dismissal iyileştirildi.
- Goal card/carousel copy ve görsel hiyerarşi daha net hale getirildi.
- Build ve ilgili savings testleri geçti.

---

### 5. Recurring Expenses — ✅ Çözüldü (özel kategori akışı)

**Önceki gözlem:**
- Varsayılan recurring kalemler (maaş, kira) ekranda görünüyor ve çalışıyor gibi.
- Kullanıcının kendi eklediği recurring kategori çalışmıyordu (bkz. §3).
- “Tekrarlayan giderlerde başka ne var?” — ürün keşfi eksik; kullanıcı akışı net değil.

**Durum:** Özel recurring kategori oluşturma ve routing düzeltildi; manuel test geçti. Weekly bölümü ve doğru section routing çalışıyor.

**Çözüm Notu:** Unicode kategori adları destekleniyor. Weekly bölümü eklendi. Tek seferlik kalemlerde frequency sorusu kaldırıldı. Duplicate validation aynı gelir/gider tipinde normalize edilmiş isimleri engelliyor. Kategori oluşturma sonrası tutar girişine devam ediliyor.

**Açık ürün sorusu:** Recurring kapsamı ve kullanıcıya sunulan seçenekler hâlâ netleştirilebilir (ürün keşfi).

---

### 6. Premium Temalar — ✅ Çözüldü

**Önceki gözlem:** Tema seçilse bile uygulama renkleri görünür şekilde değişmiyordu.

**Kök neden:** `ThemeManager` zaten vardı, seçilen tema Core Data’da saklanıyordu ve `currentTheme` `@Published` idi. Root app ve `ContentView` de `ThemeManager`’ı gözlemliyordu. Ancak DesignSystem bileşenlerinin çoğu runtime tema rengini değil, statik `BrandColors` / `Color.accentPrimary` / `brandProgress` token’larını kullanıyordu. Bu yüzden tema seçimi yalnızca küçük bir alanda görünüyordu.

**Durum:** İlk app-side accent fix uygulandı ve manuel test geçti. Purple ve Blue gibi premium temalar seçildiğinde accent layer artık görünür şekilde değişiyor.

**Çözüm Notu:**
- DesignSystem’e runtime `themeAccent` environment token’ı eklendi.
- Root app ve `ContentView`, `ThemeManager.accentColor` değerini `themeAccent` olarak inject ediyor.
- `PrimaryCTAButton`, `PremiumBadge`, Settings ikonları, picker/checkmark seçili durumları, premium highlight’lar ve güvenli non-financial progress accent’leri runtime tema rengine bağlandı.
- `ThemeManager`, `PremiumManager`, StoreKit, widget, app icon switching ve entitlement logic değiştirilmedi.

**Doğrulama:**
- Build geçti.
- `PremiumGateMatrixTests` geçti.
- Manuel testte tema seçimi uygulama accent layer’ında görünür oldu.

---

### 7. Tema Kapsamı — ✅ Karar Verildi

**Ürün kararı:** Premium temalar **sadece accent-only** çalışır. Tam uygulama reskin’i değildir.

BudgetMeter sakin, nötr ve finans odaklı kalmalı. Tema renkleri kişilik katmalı ama finansal anlamı veya okunabilirliği bozmamalı.

**Tema değişince değişmesi gerekenler:**
- Primary CTA fill
- Seçili tab tint
- Seçili picker/chip state
- Seçili row/checkmark state
- Settings içindeki non-destructive icon accent’leri
- Premium badge / premium highlight accent’i
- Non-financial progress accent’leri
- Non-status chart primary series (güvenli olduğu yerlerde)
- Theme preview UI
- Opsiyonel mascot tint / subtle glow (varsa)

**Tema değişince değişmemesi gerekenler:**
- App background
- Glass/card surfaces
- Text colors
- Gelir pozitif yeşili
- Gider/negatif kırmızı-coral rengi
- Warning/caution renkleri
- Error/destructive renkleri
- Financial status renkleri
- Layout, spacing, radius
- Core financial meaning

**Widget kararı:** Widget tema sync ilk fix kapsamı dışında bırakıldı. Widget tarafında tema desteği istenirse ayrıca shared persisted theme handling planlanmalı.

**App icon kararı:** App icon switching ana kapsam değil. Mevcut `ThemeManager` app icon denemesi blocker değil; ilk fix accent-layer görünürlüğüne odaklandı.

---

### 8. Widget — ✅ Çözüldü

**Durum:** Widget UI polish tamamlandı.

**Çözüm Notu:**
- Small Net Daily Pace widget layout’ında truncation sorunları giderildi.
- "Today’s pace", günlük pace değeri ve status satırı okunabilir hale getirildi.
- Goal yüzdesi small widget’ta doğru konumda tutuldu (header ile ana değer arasında).
- Medium widget tasarımı korunarak bırakıldı.
- Widget data/timeline logic ve premium logic değiştirilmedi.

---

### 9. Veri Dışa Aktarma + PDF Export — ✅ Çözüldü

**Gözlem:** Export çalışıyor; PDF olarak aktarım başarılı.

**Önceki sorun:** PDF çıktısı görsel olarak zayıf / çirkin görünüyordu.

**Durum:** PDF export tasarımı iyileştirildi ve manuel testte iyi göründüğü doğrulandı.

**Çözüm Notu:**
- `DataExportService` içindeki PDF çıktısı düz metin export yerine rapor formatına taşındı.
- BudgetMeter header/footer, tarih aralığı, generated date, sayfa numarası, hero summary, status card, income/expense breakdown, top categories ve okunabilir tablolar eklendi.
- Currency display, seçili uygulama para birimiyle uyumlu olacak şekilde `CurrencyDisplay` üzerinden formatlanıyor.
- Export akışı, premium gate, `PremiumManager`, StoreKit, widget, hesaplama logic’i ve export UI değiştirilmedi.

**Doğrulama:**
- Build geçti.
- `PremiumGateMatrixTests` geçti.
- Manuel testte PDF görünümü “pretty good” olarak onaylandı.

---

### 10. Face ID — ⏸️ Park Edildi (Hard Close sonrası persistence sorunu)

**Gözlem (mevcut durum):**
1. Face ID açılıyor, yüz doğrulama başarılı. ✅
2. Uygulama arka plan/ön plan geçişinde kilit çalışıyor. ✅
3. Uygulama hard close + reopen sonrası kilit bazen atlanıyor ve ayarda Face ID OFF görünebiliyor. ❌

**Beklenen:** `BiometricManager` aktifken cold start / background’dan dönüşte kimlik doğrulama istenmeli ve enabled-state kalıcı kalmalı.

**Durum Notu (22 Haziran):** Birden fazla düzeltme denemesine rağmen hard close senaryosunda enabled-state persistence sorunu devam ediyor. Konu geçici olarak park edildi.

**Park Kriteri / Sonraki teknik inceleme:**
- `AppSettings` satır tekilliği ve olası çoğalma (Core Data + CloudKit/App Group)
- `BiometricSettingsView` toggle side-effect zinciri
- Launch sırası: persisted state load vs auth restore
- Gerekirse izole “biometric persistence” test senaryosu eklenmesi

---

### 11. Daily Encourage Notification — ✅ Çözüldü

**Önceki gözlem:** Toggle’a tıklanınca *“Please enable notifications in Settings first”* mesajı çıkıyordu; izin akışı kullanıcıyı doğru yönlendirmiyordu.

**Durum:** Çözüldü. Daily Encourage Notification MVP için optional, default OFF ve basit/sakin günlük hatırlatma olarak bırakıldı.

**Çözüm Notu:**
- `notDetermined` → uygulama içinde `UNUserNotificationCenter.requestAuthorization` çağrılıyor.
- `denied` → toggle OFF kalıyor ve `Open Settings` aksiyonu ile `UIApplication.openSettingsURLString` kullanılıyor.
- `authorized` / desteklenen izinli durumlar → toggle normal şekilde enable/schedule veya disable/cancel yapıyor.
- Test notification scheduling manuel olarak doğrulandı: uygulama arka plana alındığında / telefon kilitlendiğinde bildirim başarıyla geldi.
- Foreground presentation eklendi; uygulama açıkken tetiklenen test/local notification banner/list olarak görünebilir.

**Kapsam dışı bırakılanlar:** Onboarding prompt, custom message engine, AI text, streaks ve agresif engagement dili eklenmedi.

---

### 12. İlk Kurulumda Bildirim İzni — ✅ Karar Verildi

**Karar:** İlk app launch sırasında bildirim izni istenmeyecek.

**Ürün gerekçesi:** BudgetMeter sakin ve kullanıcı kontrollü kalmalı. Bildirim izni yalnızca kullanıcı Daily Encourage Notification’ı bilinçli olarak açtığında istenecek.

**App Store / UX notu:** Bu akış App Store-safe ve Apple’ın değer önerisi sonrası izin isteme yaklaşımıyla uyumlu. Onboarding yeniden tasarlanırsa bildirim prompt’u daha sonra tekrar değerlendirilebilir.

**Durum:** İlk kurulum bildirimi belirsizliği kapatıldı; MVP’de ilk açılışta permission prompt yok.

---

### 13. Cloud Backup — ✅ Phase 5 UX düzeltmesi uygulandı

**Önceki sorun:** Kullanıcı “Account & Backup” / “Cloud Backup” görünce structured Supabase sync ile manuel backup’ı karıştırıyordu.

**Phase 5 çözümü (2026-06):**
- Ekran adı: **Account** (Account & Backup kaldırıldı)
- Yeni bölüm: **Account Sync** — giriş yapınca ücretsiz structured sync ana hikâye
- Eski “Cloud Backup” → **Manual Backup & Restore** (Premium, gelişmiş yedek)
- Gizlilik metinleri: iCloud/encryption iddiaları kaldırıldı; sync vs manuel backup ayrımı netleştirildi
- Spec: `docs/implementation/supabase_phase5_account_sync_copy_plan.md`

**Güncel mimari:**

| Katman | Ne yapıyor | Gating |
|--------|------------|--------|
| **CoreData (cihaz)** | Local-first veri | — |
| **Account sync** (Phases 1–3) | Structured Supabase sync (settings, goals, bills, transactions, categories) | Ücretsiz (giriş gerekli) |
| **Manual Backup & Restore** (`BackupService`) | Tam JSON snapshot → `user_backups` | Premium + giriş |
| **CloudKit** | Legacy engineering; UI’da tanıtılmıyor | — |

**Not:** Signed-in free kullanıcılar structured sync alır. Premium yalnızca manuel backup/restore içindir.

**Phase 5B (ayrı):** `PrivacyInfo.xcprivacy` + App Store metadata — Phase 5A doğrulandıktan sonra.

---

## Sonraki Adımlar

1. **Yüksek (Park):** Face ID enabled-state persistence (hard close sonrası)
2. **Phase 5B:** PrivacyInfo.xcprivacy + App Store metadata (Phase 5A doğrulandıktan sonra)

---

## İlgili Dosyalar

| Konu | Dosya |
|------|-------|
| Premium gate | `CoreKit/Sources/Premium/PremiumManager.swift` |
| Debug toggle | `Features/SettingsFeature/View/SettingsView.swift` |
| Kategori ekleme | `Features/Shared/CreateCategoryModal.swift` |
| Savings goals | `Features/SavingsGoalsFeature/` |
| Temalar | `CoreKit/Sources/Premium/ThemeManager.swift` |
| Tema accent token | `DesignSystem/Colors/BrandColors.swift` |
| Tema accent uygulaması | `DesignSystem/Components/Buttons/PrimaryCTAButton.swift`, `DesignSystem/Components/Badges/PremiumBadge.swift`, `Features/SettingsFeature/` |
| Face ID | `CoreKit/Sources/Security/BiometricManager.swift` |
| Bildirimler | `Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift` |
| Manual backup | `CoreKit/Sources/Backup/BackupService.swift` |
| Phase 5 copy spec | `docs/implementation/supabase_phase5_account_sync_copy_plan.md` |
| Export | `CoreKit/Sources/Export/DataExportService.swift` |
