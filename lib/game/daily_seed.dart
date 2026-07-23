/// Deterministic daily seed from local calendar date — no network.
class DailySeed {
  DailySeed(this.date);

  factory DailySeed.today() => DailySeed(DateTime.now());

  factory DailySeed.fromDate(DateTime date) =>
      DailySeed(DateTime(date.year, date.month, date.day));

  final DateTime date;

  /// Stable int for RNG (YYYYMMDD mixed).
  int get value {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final raw = y * 10000 + m * 100 + d;
    // Mix bits so consecutive days diverge more.
    return (raw * 2654435761) & 0x7fffffff;
  }

  String get label {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  String get storageKey =>
      'daily_${date.year}_${date.month}_${date.day}';
}
