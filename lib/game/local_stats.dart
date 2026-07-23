import 'package:shared_preferences/shared_preferences.dart';

import 'daily_seed.dart';

class LocalStats {
  LocalStats({
    this.lastCompletedDailyKey,
    this.bestLevel = 1,
    this.runsWon = 0,
    this.dailyStreak = 0,
    this.lastDailyWinDay,
    this.tipsSeen = false,
  });

  String? lastCompletedDailyKey;
  int bestLevel;
  int runsWon;
  int dailyStreak;
  String? lastDailyWinDay;
  bool tipsSeen;

  static const _kDaily = 'last_completed_daily';
  static const _kBest = 'best_level';
  static const _kWon = 'runs_won';
  static const _kStreak = 'daily_streak';
  static const _kLastWin = 'last_daily_win_day';
  static const _kTips = 'tips_seen';

  static Future<LocalStats> load() async {
    final p = await SharedPreferences.getInstance();
    return LocalStats(
      lastCompletedDailyKey: p.getString(_kDaily),
      bestLevel: p.getInt(_kBest) ?? 1,
      runsWon: p.getInt(_kWon) ?? 0,
      dailyStreak: p.getInt(_kStreak) ?? 0,
      lastDailyWinDay: p.getString(_kLastWin),
      tipsSeen: p.getBool(_kTips) ?? false,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    if (lastCompletedDailyKey == null) {
      await p.remove(_kDaily);
    } else {
      await p.setString(_kDaily, lastCompletedDailyKey!);
    }
    await p.setInt(_kBest, bestLevel);
    await p.setInt(_kWon, runsWon);
    await p.setInt(_kStreak, dailyStreak);
    await p.setBool(_kTips, tipsSeen);
    if (lastDailyWinDay == null) {
      await p.remove(_kLastWin);
    } else {
      await p.setString(_kLastWin, lastDailyWinDay!);
    }
  }

  Future<void> markTipsSeen() async {
    tipsSeen = true;
    await save();
  }

  void noteLevelReached(int level) {
    if (level > bestLevel) bestLevel = level;
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
