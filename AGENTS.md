# Kelime Bahis — Agent Crew

Bu proje [CrewAI](https://github.com/crewAIInc/crewAI) paketini **kullanmaz** (API key yok).
Aynı fikir uygulanır: rol tabanlı agent’lar sırayla işbirliği yapar.

Cursor kuralları: [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) Flutter + clean-code.

## Crew üyeleri

| Agent | Görev |
|-------|--------|
| DesignerAgent | Seviye hedefleri, el boyutu, tur sayısı |
| DictionaryAgent | `tr_words.txt` filtre / doğrulama |
| BalanceAgent | Harf puanları, joker çarpanları |
| ContentAgent | Boss + joker JSON üretimi |

## Çalıştırma

```bash
dart run scripts/run_crew.dart
dart run scripts/run_debate.dart
```

Çıktı: `crew/output/crew_report.json` ve güncellenen balance önerileri.

## Oyun özeti

Harf torbasından el çek → Türkçe kelime kur → joker sinerjileriyle skor üret → hedefi geç → mağazadan joker al → boss seviyelerinde kısıtlamalarla oyna. Hepsi offline.
