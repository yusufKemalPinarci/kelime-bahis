# Kelime Bahis — İlerleme (PROGRESS)

> Her özellik/oturum bitince bu dosya güncellenir. Yeni chat önce burayı okur.

**Son güncelleme:** 2026-07-29  
**Branch:** `master` (remote ile senkron)  
**Son commit:** `69171bb` — Add PROGRESS.md handoff so new chats continue systematically.

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
- [x] `lib/crew/pipeline.dart`, `AGENTS.md`, `.cursor/rules/crew-orchestration.mdc` (alwaysApply)
- [x] `dart run scripts/run_crew.dart` / `run_debate.dart`

### Oyun modu (5 harf)
- [x] Yalnızca **5 harfli** Türkçe kelime geçerli (`kWordLength = 5`)
- [x] Yerel sözlük: `assets/dictionary/tr_words.txt` — **5555** kelime, ~36 KB
- [x] Sözlük üretimi: `dart run scripts/build_five_letter_dict.dart <kaynak.txt>`
- [x] **El boyutu = 5** (`handSize = kWordLength`) — eldeki 5 harfin hepsi kelimeye gider
- [x] Boss’lar uzunluk kısıtından arındırıldı; jokerler 5 harf ekonomisine uyarlandı
- [x] UI metinleri “5 harfli” olacak şekilde güncellendi
- [x] Testler geçiyor

### Git
- [x] Branch oluşturuldu + commit + push
- [ ] PR henüz açılmadı (isteğe bağlı)

---

## Sıradaki backlog (öncelik sırası)

1. **Denge (balance)** — el=5 sonrası zorluk; torba frekansı, hedef skor, tur/atma hakkı
2. **Harf sırası UX** — seçili harfleri kaydır / yeniden sırala (5 harfte sıra kritik)
3. **Discard iyileştirmesi** — stratejik atma hissi
4. **5 harfe özel joker/boss** sinerjileri
5. Sözlüğü “yaygın kelime” odaklı sadeleştirme (nadir TDK kırp)
6. Skor/oyuncu feedback (animasyon, kaybetme özeti)
7. Android release (ikon, splash)

---

## Kritik dosyalar

| Alan | Yol |
|------|-----|
| Kelime uzunluğu | `lib/game/word_length.dart` |
| Motor | `lib/game/game_controller.dart` |
| Sözlük | `lib/game/word_dictionary.dart`, `assets/dictionary/tr_words.txt` |
| Skor/joker/boss | `lib/game/scoring.dart`, `assets/content/*.json` |
| UI | `lib/views/screens/` |
| Pipeline | `lib/crew/pipeline.dart`, `AGENTS.md` |

---

## Oturum günlüğü

| Tarih | Ne yapıldı |
|-------|------------|
| 2026-07-26 | Crew aşama→agent pipeline yazıldı |
| 2026-07-26 | 5 harf modu + yerel 5555 kelime + el=5 |
| 2026-07-26 | Branch commit + push |
| 2026-07-29 | `PROGRESS.md` eklendi (yeni chat handoff) |
