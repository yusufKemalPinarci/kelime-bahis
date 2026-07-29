# Kelime Bahis — İlerleme (PROGRESS)

> Her özellik/oturum bitince bu dosya güncellenir. Yeni chat önce burayı okur.

**Son güncelleme:** 2026-07-29  
**Branch:** `master`  
**Son iş:** Eğlence boşlukları turu (hedef eğrisi, sözlük kalite, discard→torba, altın ekonomisi)

---

## Proje kimliği

- Full offline Türkçe kelime-roguelike (Wordlike + Balatro)
- Stack: Flutter, Material 3, ChangeNotifier
- API / internet / reklam / hesap **yok**
- Crew: yerel sıralı agent’lar (`lib/crew/pipeline.dart`, `AGENTS.md`)

---

## Tamamlananlar

### Crew / süreç
- [x] Agent rolleri + aşama sırası: debate → design → dictionary → balance → content → engine → ui
- [x] `lib/crew/pipeline.dart`, `AGENTS.md`, `.cursor/rules/`

### Oyun modu (değişken uzunluk — Tur 6)
- [x] El **8** harf; kelime **2–8** harf
- [x] Geniş sözlük + uzunluk çarpanı + sıra UX

### Eğlence boşlukları (Tur 7)
- [x] Tek sürekli hedef eğrisi (`base=32`, `growth=1.22`) — L3→L4 uçurumu yok
- [x] Kısa kelime limiti (seviye ≤3 harf max 2) + 2-harf çarpan 0.5×
- [x] Sözlük kalite: 2-harf allowlist + `blocklist.txt` (`bh`/`zn` yok; `çay`/`su` var) — ~31814 kelime
- [x] Discard → `bag.returnTiles` (torabaya dönüş)
- [x] Hafif ekonomi: altın, joker `cost`, max 5 slot, reroll 1 altın
- [x] UI: tutorial metni, joker sheet, skor flash, hint indeksi
- [x] Testler geçiyor

---

## Sıradaki backlog (öncelik sırası)

1. Playtest ile altın/fiyat ince ayar
2. Boss skor cezası / joker-boss diyaloğu
3. Ses (isteğe bağlı, offline asset)
4. Android release (ikon, splash)

---

## Kritik dosyalar

| Alan | Yol |
|------|-----|
| Kelime / el / ekonomi sabitleri | `lib/game/word_length.dart` |
| Motor | `lib/game/game_controller.dart` |
| Sözlük | `lib/game/word_dictionary.dart`, `assets/dictionary/` |
| Skor/joker/boss | `lib/game/scoring.dart`, `assets/content/*.json` |
| UI | `lib/views/screens/` |

---

## Oturum günlüğü

| Tarih | Ne yapıldı |
|-------|------------|
| 2026-07-26 | Crew pipeline + 5 harf modu |
| 2026-07-29 | PROGRESS handoff |
| 2026-07-29 | El=8, 2–8 harf, ~32k sözlük |
| 2026-07-29 | Tur7: hedef/discard/ekonomi/sözlük kalite/UI cilası |
