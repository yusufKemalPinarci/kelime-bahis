# Kelime Bahis

Full offline Türkçe kelime-roguelike (Wordlike / Balatro tarzı).

İnternet, hesap, reklam ve API key **yok**.

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

1. Elinden harf seç, Türkçe kelime kur  
2. Joker’lerle skor çarpanı üret  
3. Hedefi geç, mağazadan joker al  
4. Her 4. seviyede boss kısıtı  

### Modlar

- **Klasik koşu** — rastgele seed  
- **Günlük koşu** — yerel takvimden deterministic seed (internet yok); günde bir tamamlanır  
