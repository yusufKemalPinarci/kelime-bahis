# Kelime Bahis — İlerleme (PROGRESS)

> Her özellik/oturum bitince bu dosya güncellenir. Yeni chat önce burayı okur.

**Son güncelleme:** 2026-08-06  
**Branch:** `master`  
**Son iş:** Permadeath kaldırıldı — seviye başarısız olunca yerinde tekrar başlar, koşu kaydedilip devam edilebilir; 2 harfli kelimeler

---

## Proje kimliği

- Türkçe kelime oyunu (Wordlike + Balatro ilhamı: joker/mağaza/boss); oyun mantığı/sözlük **tamamen offline**
- Stack: Flutter, Material 3, ChangeNotifier
- **Permadeath yok** (klasik/günlük): seviye kaybı = yerinde retry, koşu diskte saklanır ve "Devam et" ile sürdürülür. Sadece Endless permadeath korur. Detay: Tur 15 aşağıda
- API / hesap / sync **yok**. Gelir modeli: AdMob (ödüllü + banner, opt-in/kaldırılabilir) + tek seferlik "reklamları kaldır" IAP — yalnızca bunlar internet gerektirir (bkz. `lib/services/`)
- Crew: yerel sıralı agent’lar (`lib/crew/pipeline.dart`, `AGENTS.md`)

---

## Tamamlananlar

### Crew / süreç
- [x] Agent rolleri + aşama sırası: debate → design → dictionary → balance → content → engine → ui
- [x] `lib/crew/pipeline.dart`, `AGENTS.md`, `.cursor/rules/`
- [x] Cursor subagent’ları: `.cursor/agents/` (facilitator → ui-agent)

### Oyun modu (değişken uzunluk — Tur 6)
- [x] El **8** harf; kelime **2–8** harf (sonra Tur9’da 3–8’e çekildi)
- [x] Geniş sözlük + uzunluk çarpanı + sıra UX

### Eğlence boşlukları (Tur 7)
- [x] Tek sürekli hedef eğrisi (`base=32`, `growth=1.22`) — L3→L4 uçurumu yok
- [x] Kısa kelime limiti (seviye ≤3 harf max 2)
- [x] Sözlük kalite + `blocklist.txt`
- [x] Discard → `bag.returnTiles` (torabaya dönüş)
- [x] Hafif ekonomi: altın, joker `cost`, max 5 slot, reroll 1 altın
- [x] UI: tutorial metni, joker sheet, skor flash, hint indeksi
- [x] Testler geçiyor

### Tur 8 design (aşama 1)
- [x] `startingGold` 4→5, `shopRerollCost` 1, joker cost band 3–6 (not)
- [x] Boss: `bossTargetMultiplier` 1.1 (hedef ↑; skor cezası yok) + HUD metin kuralı
- [x] `bossDialogEnabled` + `shouldShowBossDialog` / `acknowledgeBossDialog` kancaları

### Tur 8 balance (aşama 3; dictionary skip)
- [x] `scoring.dart`: `kBossTargetMultiplier` 1.1 + `computeLevelTarget` / boss seviye yardımcısı
- [x] `balance_agent.dart`: efektif `levelTargets` (boss ×1.1), ekonomi context (gold5, cost 3–6)
- [x] Harf puanları / `letter_bag` değişmedi

### Tur 8 content (aşama 4)
- [x] 13 joker: cost hepsi 3–6 (değişiklik yok); flat value ≤12 (3 joker düşürüldü)
- [x] 9 boss: kısıt açıklamaları net; opsiyonel `dialogHint` (joker sinerji satırı)
- [x] Boss metinlerinde skor cezası / «hedef +%10» dili yok

### Tur 8 engine + UI (aşama 5–6)
- [x] Engine: `dialogHint` oku; `bossPressureHudText`; diyalog kancaları
- [x] UI: mağaza boss modal (`name` / `description` + `dialogHint` → `acknowledgeBossDialog`)
- [x] UI: playing + boss seviyesinde ikincil chip «Boss · hedef +10%» (`GameColors.bossBg`)
- [x] Tek CTA (OYNA / Devam et) korundu

### Android release
- [x] Uygulama adı: **Kelime Bahis** (`strings.xml` + Manifest)
- [x] Launcher ikon (terracotta K karosu) + adaptive icon (`#1E1612` arka plan)
- [x] Native splash (koyu `#0C1210`) — bootstrap bitene kadar korunur
- [x] Release APK: `build/app/outputs/flutter-apk/app-release.apk` + `KelimeBahis-v1.0.1.apk` (v1.0.1+2, ~53 MB; debug imza)
- [x] Release signing keystore (`android/keystore/`, `key.properties` — gitignore)
- [x] Play Store AAB: `build/app/outputs/bundle/release/app-release.aab` (~48.6 MB, release imza)
- [x] Play Store screenshots: `play_store_assets/screenshots/` (1080×1920)
- [x] Mağaza metinleri + gizlilik taslağı: `play_store_assets/listing/STORE_LISTING.md`
- [x] Bootstrap hata ekranı + LocalStats try/catch; engine unit testleri
- [x] Sözlük seed genişletme → ~31753 kelime

### Tur 9 — 3–8 harf + sözlük/UI düzeltmeleri
- [x] `kMinWordLength` 2→**3**; 2-harfli kelimeler sözlükten çıkarıldı (~31748 kelime)
- [x] `kShortWordExactLength` 3; joker `kisa_ates` «Tam 3 harfli»; `lengthMultiplier` case 2 kaldırıldı
- [x] `toUpperTr`: **ı→I / i→İ** (Dart `toUpperCase` ikisini I yapıyordu → «kısa» yanlışlıkla «kisa» sayılıyordu)
- [x] Seçim şeridi: `LetterTileChip(compact: true)` — puan taşması giderildi
- [x] Puan köşe rozeti + HUD/tutorial: «köşe sayısı puan · I ≠ İ»
- [x] `build_tr_dict.dart` minLen=3; testler yeşil

### Stitch UI (aşama 6 — görsel)
- [x] Design tokens: espresso `#17130C`, terracotta `#C0533E`, gold `#E9C349`, parchment tile `#E5DACE`
- [x] Fonts (offline): Libre Caslon Text, Work Sans, JetBrains Mono → `assets/fonts/`
- [x] Shared: `TableSurface`, `BrassPanel`, `LetterpressButton`, bone `LetterTileChip`
- [x] Ekranlar: Home / Play / Boss / Shop / Boss dialog / Joker sheet / Win / Lose
- [x] İşlevsellik korundu (OYNA, discard, hint, reorder, shop buy/sell/reroll, endless…)
- [x] Stitch’teki OYNA/DAĞARCIK/DÜKKAN/BAHİS bottom-nav **yok** (oyunda route yok)

### UX sadeleştirme (mağaza)
- [x] Sat / incele sheet / yenile / boss modal **kaldırıldı**
- [x] Akış: 2 tekliften birini seç → seviye devam; veya **Atla**
- [x] Slot doluysa otomatik satış yok; max **3** bonus
- [x] Oyunda bonuslar sadece isim satırı (dokunulmaz)

### UX — görsel ekonomi / ön yüz (Tur 10)
- [x] `GoldChip` / `GoldPriceTag` — cüzdan + mağaza fiyatı (düz «X ALTIN» yazısı yok)
- [x] `WordLengthMeter` — 3–8 kuralı metin yerine çubuk (min çizgisi)
- [x] Home: «Nasıl oynanır?» kutusu kalktı; kelime → altın → bonus döngüsü
- [x] Play: tutorial mesajları gizlendi; feedback kısa; bonus chip’leri
- [x] Shop: büyük cüzdan + fiyat etiketi; 3 slot görseli
- [x] `ScoreHud` + `HandsPips`: seviye/puan tek panel; «X hak kaldı» → noktalar
- [x] Boss: tek kart + `+%` rozeti (ayrı pressure chip yok)

### Tur 11 — kalıcı rütbe sistemi + ölü kod temizliği
- [x] `LocalStats.lifetimeScore` (kalıcı, `SharedPreferences`) — her oynanan kelime + verim bonusu ekler; kayıpta da kaydedilir
- [x] `lib/game/rank.dart`: 7 kademeli Türkçe rütbe eğrisi (Çaylak → Kelime Baronu)
- [x] `RankBadge` (`lib/views/widgets/rank_badge.dart`): rütbe adı + sonraki rütbeye ilerleme çubuğu
- [x] Home ekranı: rekor satırı yerine `RankBadge`; kelime sayısı/rekor seviye alt satırda kaldı
- [x] Bitiş ekranı: koşuda kazanılan ömür boyu puan + rütbe atladıysa «YENİ RÜTBE» satırı
- [x] Ölü kod temizliği: kullanılmayan `rerollShop`/`sellJoker`/`kShopRerollCost`/`shopRerollsLeft`, kapalı boss-diyalog kancaları (`kBossDialogEnabled`, `shouldShowBossDialog`, `acknowledgeBossDialog`), hiç okunmayan `LocalStats.tipsSeen`, ve artık hiçbir mesajla eşleşmeyen `_isActionFeedback` filtre listesi kaldırıldı
- [x] Joker isim cilası: «Altılı Bonus» → «Altılı Vuruş», «Sekizli» → «Sekiz Nişanı» (bosses.json `dialogHint` metinleri eşleştirildi)
- [x] `flutter analyze` temiz, `flutter test` 35/35 yeşil (widget testindeki belirsiz `find.textContaining('KELİME')` eşleşmesi de düzeltildi)
- [x] Canlı doğrulama: `emulator-5554` disk doluydu (`Requested internal only, but not enough space`), boş `emulator-5556` (~3.5GB) kullanıldı — RankBadge + bitiş ekranı sorunsuz render edildi

### Tur 12 — Play Store yükleme öncesi hazırlık
- [x] Güvenlik: `play_store_assets/listing/KEYSTORE_BACKUP.txt` (düz metin keystore şifresi) artık `.gitignore`'da — önceden yanlışlıkla `git add -A` ile commit edilebilirdi
- [x] Ufak i18n düzeltmesi: `HudLabel` artık `toUpperTr` kullanıyor — «EN İYİ KELİMEN» yerine yanlışlıkla «EN IYI KELİMEN» basıyordu (mağaza ekran görüntüsünde fark edildi)
- [x] 6 resmi ekran görüntüsü yeniden çekildi (`play_store_assets/screenshots/`, 1080×2400, `emulator-5556`) — eski görüntüler RankBadge öncesiydi
- [x] `STORE_LISTING.md`: «ipuçları görüldü» veri maddesi kaldırıldı (kod da kaldırılmıştı), ömür boyu puan/rütbe maddesi eklendi, ÖZELLİKLER'e rütbe sistemi eklendi, gizlilik politikası taslağına geliştirici adı/e-postası dolduruldu (**yayınlamadan önce doğrula**), tarih güncellendi
- [x] Versiyon 1.0.2+3 → **1.0.3+4**
- [x] Release build: `build/app/outputs/bundle/release/app-release.aab` (~50.9 MB) + `build/app/outputs/flutter-apk/app-release.apk` (~56 MB) — `apksigner` ile imza doğrulandı (CN=Kelime Bahis, gerçek release sertifikası, debug değil)
- [x] `flutter analyze` temiz, `flutter test` 35/35 yeşil

**Play Console'a yüklemeden önce hâlâ kullanıcının kendisinin yapması gerekenler** (Claude'un bu hesaba erişimi yok):
- [ ] Gizlilik politikası metnini (`STORE_LISTING.md` içinde) bir genel URL'ye barındır (GitHub Pages / Notion public / kendi domain)
- [ ] Geliştirici adı/e-postasının doğru olduğunu teyit et (varsayılan olarak dolduruldu)
- [ ] Play Console'da yeni sürüm oluştur, `app-release.aab` yükle, gizlilik politikası URL'sini gir
- [ ] Data safety formunu doldur (taslak `STORE_LISTING.md`'de)
- [ ] Store listing metnini (kısa/uzun açıklama, ekran görüntüleri, feature graphic) yapıştır
- [ ] İncelemeye gönder

### Tur 13 — gelir modeli (AdMob + IAP)
- [x] `.cursor/rules/project-kelime-bahis.mdc` güncellendi — proje artık kesin "reklam yok" demiyor; sadece **zorunlu** reklam yasak (interstitial dahil)
- [x] `pubspec.yaml`: `google_mobile_ads: ^5.3.1`, `in_app_purchase: ^3.2.3`
- [x] `AndroidManifest.xml`: `INTERNET`/`ACCESS_NETWORK_STATE` izni + AdMob App ID meta-data (şu an **Google'ın test App ID'si** — gerçek ID'yle değiştirilmeli)
- [x] `lib/services/ad_config.dart` — reklam birimi ID'leri + `remove_ads` ürün ID'si tek yerde (şu an Google'ın test ID'leri)
- [x] `lib/services/ads_controller.dart` — banner + ödüllü reklam yaşam döngüsü (`ChangeNotifier`); yüklenemezse sessizce boş kalır, oyunu bloklamaz
- [x] `lib/services/purchase_controller.dart` — tek seferlik `remove_ads` non-consumable IAP; yerel önbellek (`SharedPreferences`) + `restorePurchases()`
- [x] `lib/main.dart`: iki yeni controller bootstrap'tan **sonra**, arka planda (`unawaited`) başlatılıyor — açılışı geciktirmiyor
- [x] UI: Home ekranında banner reklam yuvası (`BannerAdSlot`, reklam yoksa yer kaplamaz) + "Reklamları kaldır" metin butonu; mağazada ödüllü reklam ile "+3 altın" butonu (`GameController.grantBonusGold`)
- [x] `STORE_LISTING.md` + `PROGRESS.md` proje kimliği: "reklam yok" iddiaları kaldırıldı, AdMob/IAP veri toplama açıklaması ve Play Console "içerir reklam"/Data safety rehberi eklendi
- [x] `flutter analyze` temiz, `flutter test` 35/35 yeşil (widget testi gerçek AdMob/Billing platform kanalına dokunmuyor — controller'lar `init()` edilmeden inşa ediliyor)

- [x] Gerçek AdMob ID'leri girildi (2026-08-06): App ID `ca-app-pub-6704147140468357~2272933363`, banner `.../7943082501`, ödüllü `.../7274812750` — `ad_config.dart` + `AndroidManifest.xml` güncellendi, `flutter analyze` temiz
- [ ] **Not:** Yeni reklam birimleri AdMob'da doldurmaya başlaması ~1 saat sürebilir; hemen "no fill" görülmesi normal. Gerçek ID'lerle kendi cihazında reklamlara **tıklama/çok fazla görüntüleme** — geçersiz trafik riski AdMob hesabını askıya aldırabilir (test etmek için AdMob'un "test device" özelliğini kullan)

- [x] Gerçek ID'lerle release AAB yeniden build edildi (2026-08-06): `build/app/outputs/bundle/release/app-release.aab` (~55,5 MB) — merged manifest'te `com.android.vending.BILLING` + gerçek AdMob App ID doğrulandı
- [x] Versiyon 1.0.3+4 → **1.0.4+5**; AAB yeniden build edildi (~52,9 MB) + APK imzası tekrar doğrulandı (aynı release sertifikası, CN=Kelime Bahis)

**Yayından önce kullanıcının yapması gerekenler:**
- [ ] Play Console → Uygulama içi ürünler → `remove_ads` ID'siyle tek seferlik (non-consumable) ürün oluştur, fiyat belirle (öneri: $2.99 taban) — detay aşağıda
- [ ] Play Console'da "Uygulamanız reklam içeriyor mu?" → Evet; Data safety formunu yeni taslağa göre güncelle

### Tur 14 — ikon yenileme + oynanış/sözlük düzeltmeleri
- [x] **Yeni uygulama ikonu**: `scripts/generate_app_icon.py` (Pillow, tekrar üretilebilir) — markanın kendi paletini/fontunu (LibreCaslonText, terracotta/gold/espresso) kullanan sade bir "K" karosu. Eskisi (AI görseliyle üretilmiş, yoğun desenli, adaptive-icon güvenli alanına dikkat etmeyen) yerine geçti
  - `assets/branding/app_icon.png` (düz kare, mağaza/legacy), `app_icon_foreground.png` (şeffaf, adaptive-icon güvenli alanı için dolgulu), `app_icon_background.png` (radyal gradyan — TableSurface ile birebir aynı) — üçü de `flutter_launcher_icons` + `flutter_native_splash` için ayrı ayrı bağlandı
  - Gerçek cihazda (dairesel maske) doğrulandı: temiz, okunaklı, kırpma yok
  - Bilinen kozmetik not: bu emülatörün açılış (splash) ekranı ikonu sekizgen bir sistem maskesiyle kırpıyor — asıl launcher ikonu (kullanıcının asıl gördüğü) etkilenmiyor; gerçek cihazlarda muhtemelen düzgün daire. İzlemeye değer ama engelleyici değil
- [x] **Harf torbası dengelendi** (`lib/game/letter_bag.dart`): resmi Türkçe Scrabble oranı (~%40 sesli) 8 harflik tek elde kelime kurmayı zorlaştırıyordu → ~%30 sesliye çekildi, k/l/n/r/t/s gibi yaygın sessizler güçlendirildi
- [x] **Sözlük genişletildi**: `vur, gel, git, bak, dur, koş, sor, ver` gibi çok yaygın emir kipi fiil kökleri sözlükte yoktu (kaynak liste yalnızca "-mek/-mak" mastar biçimlerini içeriyordu). ~70 kök `scripts/build_tr_dict.dart`'ın seed listesine eklendi, yeniden üretildi: 31753 → **31831 kelime**
- [x] **Koşu ortasında çıkış yolu yoktu** (özellikle günlük modda "sıkışma" şikayeti) — `GameScreen`'e her zaman görünen bir geri butonu + "Koşudan çık? İlerlemen kaybolur" onay diyaloğu eklendi (`_ExitIconButton`, playing + shop fazlarında)
- [x] Görsel: `GameColors.barTrack` arka planla neredeyse aynıydı → %0 ilerlemede rütbe/skor çubukları görünmüyordu; daha açık bir tona çekildi
- [x] Versiyon 1.0.4+5 → **1.0.5+6**; AAB (~45,5 MB) + APK yeniden build edildi, imza doğrulandı (CN=Kelime Bahis)
- [x] `flutter analyze` temiz, `flutter test` 35/35 yeşil, tüm değişiklikler gerçek cihazda (emulator-5556) canlı doğrulandı
- [x] Play Console mağaza görselleri: `scripts/generate_feature_graphic.py` (aynı ikon üretim koduna dayanır) ile **özellik grafiği** (1024×500) yeni ikonla yeniden üretildi — eskisi hâlâ eski (AI-üretimi, ahşap desenli) ikonu gösteriyordu. `play_store_assets/listing/app_icon_512.png` de eklendi (Play Console'un istediği tam 512×512 simge dosyası)

### Tur 15 — permadeath kaldırıldı, koşu kaydı/devam, 2 harfli kelimeler
- [x] **Klasik/günlükte permadeath yok artık**: `GameController.playWord`'de `handsLeft<=0` dalı — endless hâlâ `RunPhase.lost` (skor-avı, kasıtlı permadeath); klasik/günlükte seviye altın/joker/seviye numarası korunarak **yerinde** yeniden başlar (`_setupLevel()` + yeni el), mesaj: "Hedefe N puan kala tur bitti — seviye yeniden başladı."
- [x] **Koşu kaydı/devam** (`LocalStats.savedRun*` + `SharedPreferences`): her seviye ilerlemesinde (`advanceAfterShop`, seviye 2+) otomatik kaydedilir; klasik kazanınca silinir; günlük kaydı gün değişirse `bootstrap()`'ta budanır (`_pruneStaleSavedRun`). `GameController.resumeRun()` seviye/altın/joker'i geri yükler. Endless kasıtlı olarak kaydedilmez.
- [x] Ana ekran: OYNA → kayıt varsa **"DEVAM ET · Seviye N"**; altında küçük "Yeni koşu başlat" (onaylı silme). Günlük butonu da aynı mantıkla kendi kaydını gösterir.
- [x] Çıkış onay diyaloğu güncellendi: sadece gerçekten bir kayıt varsa ("Seviye N'e ... dönebilirsin") söylüyor; seviye 1'in ortasında (henüz kayıt yokken) "İlerlemen kaybolur" diyor — ilk yanlış/aşırı iyimser metin canlı testte yakalanıp düzeltildi
- [x] **2 harfli kelimelere izin verildi** (`kMinWordLength` 3→2, `lengthMultiplier` case 2 = 0.7×). `scripts/build_tr_dict.dart` minLen 2; ~35 yaygın 2 harfli kök seed'e eklendi (bu, gel, ne, su, ev, ok, ki, mi/mı/mu/mü, ve, ya, ye, ad, üç, de/da, iç, iş, öz, ön...)
  - **Kalite sorunu bulundu ve düzeltildi**: minLen=2 yapılınca kaynak liste periyodik tablo sembollerini (`al, ar, na, fe, cu, li, ...`) gerçek kelime sanıyordu — 117 tanesi `assets/dictionary/blocklist.txt`'e eklendi. Sonuç: 61 temiz, yaygın, aile-dostu 2 harfli kelime → sözlük 31892 kelime
- [x] **LevelStrip** (`lib/views/widgets/level_strip.dart`): 12 seviyelik ilerleme şeridi, mevcut/geçilen/gelecek seviyeler + boss seviyeleri (küçük elmas ikonu) tek bakışta görünür; GameScreen'de (endless hariç) gösterilir
- [x] `.cursor/rules/project-kelime-bahis.mdc` güncellendi — proje artık "roguelike/permadeath" değil, "seviye kaybı = retry" olarak tanımlı
- [x] 3 yeni engine testi (`test/engine_test.dart`): retry-in-place, endless permadeath korunuyor, `resumeRun` doğru seviye/altın/joker geri yüklüyor — hepsi gerçek asset'lerle deterministik
- [x] `flutter analyze` temiz, `flutter test` 38/38 yeşil, tüm akış (seviye geç → çık → ana ekranda DEVAM ET → devam et → doğru seviye/altın) gerçek cihazda uçtan uca doğrulandı

---

## Sıradaki backlog (öncelik sırası)

1. Play Console'da `remove_ads` IAP ürününü oluştur + fiyatla
2. Facilitator: `kShippedFeatureIds` içine Tur 8 (+ Tur9) id’lerini ekle (`debate_agents.dart`)
3. Ses (isteğe bağlı, offline asset) — ertelendi

---

## Kritik dosyalar

| Alan | Yol |
|------|-----|
| Kelime / el / ekonomi sabitleri | `lib/game/word_length.dart` |
| Türkçe casing | `lib/game/turkish.dart` (`normalizeTr`, `toUpperTr`) |
| Motor | `lib/game/game_controller.dart` |
| Sözlük | `lib/game/word_dictionary.dart`, `assets/dictionary/` |
| Skor/joker/boss | `lib/game/scoring.dart`, `assets/content/*.json` |
| Harf torbası dağılımı | `lib/game/letter_bag.dart` (`kLetterBagCounts`) |
| Harf taşı UI | `lib/views/widgets/letter_tile_chip.dart` |
| UI | `lib/views/screens/` |
| Uygulama ikonu (üretici script) | `scripts/generate_app_icon.py` → `assets/branding/app_icon*.png` |
| Reklam / IAP | `lib/services/ad_config.dart`, `ads_controller.dart`, `purchase_controller.dart` |
| Branding / ikon | `assets/branding/app_icon.png` |
| Theme / renk | `lib/views/theme/game_colors.dart`, `game_theme.dart` |
| Fonts | `assets/fonts/` |

---

## Oturum günlüğü

| Tarih | Ne yapıldı |
|-------|------------|
| 2026-08-06 | Tur15: permadeath kaldırıldı (retry-in-place), koşu kaydı/devam, 2 harfli kelimeler + periyodik tablo temizliği, LevelStrip |
| 2026-08-06 | Tur14: yeni uygulama ikonu, harf torbası dengelendi, sözlüğe fiil kökleri eklendi, koşudan çıkış butonu, v1.0.5+6 |
| 2026-08-06 | Tur13: AdMob (ödüllü+banner) + reklamları kaldır IAP eklendi, proje kuralı güncellendi, listing/privacy AdMob'a göre güncellendi |
| 2026-08-05 | Tur12: v1.0.3+4 AAB/APK release build + imza doğrulama, ekran görüntüleri yenilendi, listing metni güncellendi, keystore notu gitignore'a eklendi |
| 2026-08-05 | Tur11: lifetimeScore + rütbe sistemi, RankBadge, ölü kod temizliği, joker isim cilası |
| 2026-07-30 | UX: ScoreHud + HandsPips; boss tek kart +% |
| 2026-07-30 | UX: GoldChip + WordLengthMeter; home/play/shop metin sadeleştirme |
| 2026-07-29 | Play Store: AAB release imza, screenshots 1080×1920, listing metinleri |
| 2026-07-29 | Bootstrap error UI + LocalStats try/catch; engine testleri; sözlük ~31.7k |
| 2026-07-29 | Release APK v1.0.1 (~53 MB) |
| 2026-07-29 | Mağaza sade: seç/atla; sat-incele-yenile-modal yok |
| 2026-07-29 | Stitch UI kit → Flutter (table/tile/CTA/HUD) |
| 2026-07-26 | Crew pipeline + 5 harf modu |
| 2026-07-29 | PROGRESS handoff |
| 2026-07-29 | El=8, 2–8 harf, ~32k sözlük |
| 2026-07-29 | Tur7: hedef/discard/ekonomi/sözlük kalite/UI cilası |
| 2026-07-29 | `.cursor/agents/` crew subagent’ları (7 aşama) |
| 2026-07-29 | Tur8 design: altın5, boss×1.1 hedef, diyalog kancası |
| 2026-07-29 | Tur8 balance: hedef×1.1, gold5, cost 3–6; letterPoints sabit |
| 2026-07-29 | Tur8 content: flat≤12; 9× dialogHint; cost band doğrulandı |
| 2026-07-29 | Tur8 UI: boss modal + baskı chip; pipeline 0→6 tamam |
| 2026-07-29 | Android release: ikon+splash+APK v1.0.0 (~54 MB) |
| 2026-07-29 | Tur9: min3, ı/i casing, compact puan rozeti, sözlük ~31.7k |
