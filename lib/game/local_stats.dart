import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_seed.dart';

class LocalStats {
  LocalStats({
    this.lastCompletedDailyKey,
    this.bestLevel = 1,
    this.runsWon = 0,
    this.dailyStreak = 0,
    this.lastDailyWinDay,
    this.lifetimeScore = 0,
    this.savedRunLevel,
    this.savedRunGold = 0,
    this.savedRunJokerIds = const [],
    this.savedRunMode,
    this.savedRunDailyKey,
  });

  String? lastCompletedDailyKey;
  int bestLevel;
  int runsWon;
  int dailyStreak;
  String? lastDailyWinDay;

  /// Kalıcı toplam puan — rütbe ilerlemesinin kaynağı ([lib/game/rank.dart]).
  int lifetimeScore;

  /// Yarım kalmış koşu — uygulama kapansa/çıkılsa bile kaldığı yerden
  /// devam edilebilsin. `savedRunMode`: 'classic' | 'daily'.
  int? savedRunLevel;
  int savedRunGold;
  List<String> savedRunJokerIds;
  String? savedRunMode;
  String? savedRunDailyKey;

  bool get hasSavedRun => savedRunLevel != null;

  static const _kDaily = 'last_completed_daily';
  static const _kBest = 'best_level';
  static const _kWon = 'runs_won';
  static const _kStreak = 'daily_streak';
  static const _kLastWin = 'last_daily_win_day';
  static const _kLifetimeScore = 'lifetime_score';
  static const _kSavedLevel = 'saved_run_level';
  static const _kSavedGold = 'saved_run_gold';
  static const _kSavedJokers = 'saved_run_jokers';
  static const _kSavedMode = 'saved_run_mode';
  static const _kSavedDailyKey = 'saved_run_daily_key';

  static Future<LocalStats> load() async {
    // İstatistik okunamazsa oyun varsayılanlarla açılmalı — asla crash etme.
    try {
      final p = await SharedPreferences.getInstance();
      return LocalStats(
        lastCompletedDailyKey: p.getString(_kDaily),
        bestLevel: p.getInt(_kBest) ?? 1,
        runsWon: p.getInt(_kWon) ?? 0,
        dailyStreak: p.getInt(_kStreak) ?? 0,
        lastDailyWinDay: p.getString(_kLastWin),
        lifetimeScore: p.getInt(_kLifetimeScore) ?? 0,
        savedRunLevel: p.getInt(_kSavedLevel),
        savedRunGold: p.getInt(_kSavedGold) ?? 0,
        savedRunJokerIds: p.getStringList(_kSavedJokers) ?? const [],
        savedRunMode: p.getString(_kSavedMode),
        savedRunDailyKey: p.getString(_kSavedDailyKey),
      );
    } catch (e) {
      debugPrint('LocalStats.load başarısız, varsayılanlar kullanılıyor: $e');
      return LocalStats();
    }
  }

  Future<void> save() async {
    // Fire-and-forget çağrılabilir; yazma hatası oyunu düşürmemeli.
    try {
      final p = await SharedPreferences.getInstance();
      if (lastCompletedDailyKey == null) {
        await p.remove(_kDaily);
      } else {
        await p.setString(_kDaily, lastCompletedDailyKey!);
      }
      await p.setInt(_kBest, bestLevel);
      await p.setInt(_kWon, runsWon);
      await p.setInt(_kStreak, dailyStreak);
      await p.setInt(_kLifetimeScore, lifetimeScore);
      if (lastDailyWinDay == null) {
        await p.remove(_kLastWin);
      } else {
        await p.setString(_kLastWin, lastDailyWinDay!);
      }
      if (savedRunLevel == null) {
        await p.remove(_kSavedLevel);
        await p.remove(_kSavedGold);
        await p.remove(_kSavedJokers);
        await p.remove(_kSavedMode);
        await p.remove(_kSavedDailyKey);
      } else {
        await p.setInt(_kSavedLevel, savedRunLevel!);
        await p.setInt(_kSavedGold, savedRunGold);
        await p.setStringList(_kSavedJokers, savedRunJokerIds);
        await p.setString(_kSavedMode, savedRunMode ?? 'classic');
        if (savedRunDailyKey == null) {
          await p.remove(_kSavedDailyKey);
        } else {
          await p.setString(_kSavedDailyKey, savedRunDailyKey!);
        }
      }
    } catch (e) {
      debugPrint('LocalStats.save başarısız: $e');
    }
  }

  void saveRun({
    required String mode,
    required int level,
    required int gold,
    required List<String> jokerIds,
    String? dailyKey,
  }) {
    savedRunLevel = level;
    savedRunGold = gold;
    savedRunJokerIds = jokerIds;
    savedRunMode = mode;
    savedRunDailyKey = dailyKey;
  }

  void clearSavedRun() {
    savedRunLevel = null;
    savedRunGold = 0;
    savedRunJokerIds = const [];
    savedRunMode = null;
    savedRunDailyKey = null;
  }

  void noteLevelReached(int level) {
    if (level > bestLevel) bestLevel = level;
  }

  void addScore(int amount) {
    if (amount <= 0) return;
    lifetimeScore += amount;
  }

  void noteClassicWin() {
    runsWon += 1;
  }

  void noteDailyWin(DailySeed seed) {
    lastCompletedDailyKey = seed.storageKey;
    final key = seed.storageKey;
    if (lastDailyWinDay != null) {
      final prev = _parseKey(lastDailyWinDay!);
      final cur = DateTime(seed.date.year, seed.date.month, seed.date.day);
      if (prev != null && cur.difference(prev).inDays == 1) {
        dailyStreak += 1;
      } else if (lastDailyWinDay != key) {
        dailyStreak = 1;
      }
    } else {
      dailyStreak = 1;
    }
    lastDailyWinDay = key;
    runsWon += 1;
  }

  static DateTime? _parseKey(String key) {
    final parts = key.split('_');
    if (parts.length < 4) return null;
    final y = int.tryParse(parts[1]);
    final m = int.tryParse(parts[2]);
    final d = int.tryParse(parts[3]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
