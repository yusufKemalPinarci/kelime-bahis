# Kelime Bahis

Türkçe kelime-roguelike (Wordlike / Balatro tarzı).

Oynanış tamamen offline. Reklam (AdMob banner/ödüllü) ve tek seferlik
"reklamları kaldır" satın alımı (Google Play Billing) için internet
gerekir; hesap oluşturma yok, üçüncü taraf API key kullanılmıyor.

## Çalıştır

```bash
flutter pub get
flutter run
```

## Yerel Crew (CrewAI tarzı, API’siz)

[CrewAI](https://github.com/crewAIInc/crewAI) paketi entegre **edilmedi**.  
Aynı model (`Agent` → `Task` → `Crew.kickoff`) yerelde, kural tabanlı agent’larla çalışır:

```bash
dart run scripts/run_crew.dart
```

Agent sırası: Designer → Dictionary → Balance → Content

## Cursor kuralları

[PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) içinden:

- `flutter-app-expert-cursorrules-prompt-file.mdc`
- `flutter-development-guidelines-cursorrules-prompt-file.mdc`
- `clean-code.mdc`
- `ascii-simulation-game-cursorrules-prompt-file.mdc`

Artı proje kuralları: `project-kelime-bahis.mdc`, `crew-orchestration.mdc`

## Oynanış

1. Her seviye bir kelime uzunluğu demek: Seviye 1 → 2 harf, ... Seviye 7 → 8
   harf (`lengthForLevel`), elindeki 8 harften tam o uzunlukta Türkçe kelime kur
2. Kısa kelime güvenli / uzun kelime yüksek skor; joker sinerjisi
3. Hedefi geç, mağazadan joker al (koşu başlamadan önce de bir kez mağaza açılır)
4. Her 4. seviyede + 7. (final) seviyede boss kısıtı
5. Bilemediğinde **Pas** (elin tamamını bedavaya yeniler) veya **İflas**
   (koşuyu 1. seviyeden sıfırlar) hakların var

Sözlük: `assets/dictionary/tr_words.txt` (~32k × 2–8 harfli Türkçe kelime, offline).  
Yeniden üret: `dart run scripts/build_tr_dict.dart`

### Modlar

- **Klasik koşu** — rastgele seed  
- **Günlük koşu** — yerel takvimden deterministic seed (internet yok); günde bir tamamlanır  
