# Kelime Bahis — Agent Crew

Bu proje [CrewAI](https://github.com/crewAIInc/crewAI) paketini **kullanmaz** (API key yok).
Aynı fikir: rol tabanlı agent’lar **sıralı** işbirliği yapar. Kaynak: `lib/crew/pipeline.dart`.

Cursor kuralları: [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) Flutter + clean-code.

---

## Agent görevleri

| Agent | Rol | Görev (ne yapar) | Dokunmaz |
|-------|-----|------------------|----------|
| **DesignerAgent** | Oyun Tasarımcısı | El boyutu, tur/atım, seviye ritmi, mağaza seçim sayısı, UX akışı (tek hedef / tek CTA) | Harf puanı tablosu, sözlük filtresi, joker JSON gövdesi |
| **DictionaryAgent** | Sözlük Uzmanı | `tr_words.txt` filtre/doğrulama; **2–8 harf**; yalnızca Türkçe harf; offline `WordDictionary` | Skor formülü, boss kısıtları, UI teması |
| **BalanceAgent** | Denge Mühendisi | Harf puanları, seviye hedefleri, joker çarpan üst sınırları, torba dengesi | Sözlük kelime listesi, boss metinleri, ekran layout |
| **ContentAgent** | İçerik Üreticisi | `jokers.json` / `bosses.json`, Türkçe isimler, kısıt açıklamaları, görsel/metin cilası | Motor matematiği, sözlük API’si (yok), ekonomi formülü |
| **Facilitator** | Kolaylaştırıcı | Tartışma turunda önerileri skorlar; onaylı backlog (`approved`) üretir | Doğrudan oyun kodu yazmaz |

---

## Aşama → agent sırası

Özellik veya içerik işi **bu sırayla** ilerler. Bir aşama bitmeden sonrakine geçilmez.

| # | Aşama | Agent | Task adı | Çıktı |
|---|-------|-------|----------|-------|
| 0 | `debate` | Facilitator (+ 4 pitch agent) | `facilitate` | `crew/output/debate_decisions.json` |
| 1 | `design` | DesignerAgent | `design_loop` | `design` (handSize, turlar, baz hedef…) |
| 2 | `dictionary` | DictionaryAgent | `prepare_dictionary` | `wordCount` + örnek kelimeler |
| 3 | `balance` | BalanceAgent | `balance_economy` | `letterPoints` + `levelTargets` |
| 4 | `content` | ContentAgent | `generate_content` | `assets/content/*.json` |
| 5 | `engine` | Designer + Balance | `wire_engine` | `lib/game/`, `lib/models/` |
| 6 | `ui` | Content + Designer | `polish_ui` | `lib/views/`, `lib/main.dart` |

**İçerik senkronu** (otomatik Dart crew): aşama 1→4  
**Uygulama geliştirme** (Cursor): 0→6; her aşamada yalnızca o aşamanın `owns` yollarına dokun.

```
debate → design → dictionary → balance → content → engine → ui
```

---

## Çalıştırma

```bash
dart run scripts/run_debate.dart   # aşama 0
dart run scripts/run_crew.dart     # aşama 1–4
```

Çıktı: `crew/output/crew_report.json`, `crew/output/debate_decisions.json`, gerekirse `assets/content/`.

---

## Cursor’da sistematik iş akışı

1. Büyük özellik → `run_debate.dart` → onaylı `id`’leri uygula  
2. Mekanik / sayı değiştiyse sırayla design → dictionary → balance → content  
3. Sonra `lib/game` (engine), en sonda `lib/views` (ui)  
4. Aşama sahibi olmayan agent’ın klasörüne yazma  

---

## Oyun özeti

Harf torbasından el çek (8) → seviyenin gerektirdiği tam uzunlukta (2–8
harf, seviye = uzunluk) Türkçe kelime kur → joker sinerjileriyle skor üret
→ hedefi geç → mağazadan joker al → boss seviyelerinde kısıtlamalarla oyna.
Oynanış offline; reklam (AdMob) ve "reklamları kaldır" satın alımı (Play
Billing) için internet gerekir.
